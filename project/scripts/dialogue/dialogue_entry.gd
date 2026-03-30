class_name DialogueEntry
extends Node

@export_file("*.json") var json_path: String

@export var entry_name := "start"
@export var auto_start := false

@export var parent_signal_trigger: StringName
@export var state: Node

var _dialogue_data := DialogueData.new()
var _current_event_key := ""
var _current_choices: Array[DialogueEvent.DialogueChoice] = []
var _sequence_index: int = -1


func _ready() -> void:
	if parent_signal_trigger:
		if get_parent().has_signal(parent_signal_trigger):
			util.aok(get_parent().connect(parent_signal_trigger, start))
		else:
			assert(false, str("parent does not have signal: ", parent_signal_trigger))

	assert(json_path, str(get_path(), ": json_path is not set"))

	match util.parse_json_file(json_path):
		[var data, OK]:
			var res := gdserde.deserialize_object(_dialogue_data, data)
			res.expect_ok()
			#print(gdserde.serialize_object(_dialogue_data))
		[_, var err]:
			util.aok(util.as_err(err))

	assert(
		not _dialogue_data.events.is_empty(),
		str(get_path(), ": no events loaded from ", json_path),
	)
	assert(
		_dialogue_data.events.has(entry_name),
		str(get_path(), ": missing entry '", entry_name, "' in ", json_path),
	)

	if auto_start:
		call_deferred(&"start")


func start() -> void:
	if _current_event_key:
		stop()

	_current_event_key = entry_name
	util.aok(gamestate.dialogue_layer.advanced.connect(_on_advance))
	signalbus.dialogue_started.emit()
	_start_next_event()


func jump_to_event(event_key: String) -> void:
	if not _current_event_key:
		start()

	_current_event_key = event_key
	_sequence_index = -1
	_start_next_event()


func _interpolate(text: String) -> String:
	if not text.contains("${"):
		return text

	var match_var := ""
	var out := ""
	var i := 0
	while i < text.length():
		if text[i] == "$" and text[i + 1] == "{":
			i += 2
			while text[i] != "}":
				match_var += text[i]
				i += 1
				if i == text.length():
					assert(false, str("invalid format string: ", text))
					return text
			out += str(state.get(match_var))
			match_var = ""
		else:
			out += text[i]
		i += 1

	return out


func _fire_before(event: DialogueEvent) -> void:
	_call_callback(event.callback)
	_call_callback(event.before)


func _fire_after(event: DialogueEvent) -> void:
	_call_callback(event.after)


func _start_next_event() -> void:
	if not _current_event_key:
		stop()
		return

	var event: DialogueEvent = _dialogue_data.events[_current_event_key]
	_fire_before(event)
	_sequence_index = -1

	while not event.text and not event.choices and not event.sequence:
		_current_event_key = _dialogue_data.get_next(state, _current_event_key)
		if not _current_event_key:
			stop()
			return
		event = _dialogue_data.events[_current_event_key]
		_fire_before(event)

	if event.sequence:
		_sequence_index = 0
		_render_sequence_entry()
		return

	var speaker := event.speaker
	var text: Array[String] = []
	for line in event.text:
		text.push_back(_interpolate(line))

	_current_choices.clear()
	var choice_texts: PackedStringArray = []
	for choice in event.choices:
		if _dialogue_data.check_condition(state, choice.next):
			_current_choices.push_back(choice)
			util.expect_false(choice_texts.push_back(choice.text))

	gamestate.dialogue_layer.render(speaker, text, choice_texts)


func _render_sequence_entry() -> void:
	var event: DialogueEvent = _dialogue_data.events[_current_event_key]
	var entry: DialogueEvent.DialogueSequenceEntry = event.sequence[_sequence_index]
	var text: Array[String] = []
	for line in entry.text:
		text.push_back(_interpolate(line))
	var no_choices: PackedStringArray = []
	gamestate.dialogue_layer.render(entry.speaker, text, no_choices)


func _on_advance(index: int) -> void:
	var event: DialogueEvent = _dialogue_data.events[_current_event_key]

	if _sequence_index >= 0:
		_sequence_index += 1
		if _sequence_index < event.sequence.size():
			_render_sequence_entry()
			return
		_sequence_index = -1

	_fire_after(event)

	if _current_choices:
		var choice := _current_choices[index]
		_call_callback(choice.callback)
		_current_event_key = choice.next
	else:
		_current_event_key = _dialogue_data.get_next(state, _current_event_key)

	_start_next_event()


func _call_callback(callback: DialogueEvent.DialogueCallback) -> void:
	if callback.name:
		assert(
			state != null,
			str(
				get_path(),
				": 'state' export is not set, needed for callback '",
				callback.name,
				"' (json: ",
				json_path,
				")",
			),
		)
		assert(
			state.has_method(callback.name),
			str(
				get_path(),
				": state (",
				state.get_path(),
				") does not have method '",
				callback.name,
				"'",
			),
		)
		var args := []
		for arg in callback.args:
			if arg is String and arg.begins_with("$"):
				args.push_back(state.get(arg.substr(1)))
			else:
				args.push_back(arg)
		state.callv(callback.name, args)


func stop() -> void:
	gamestate.dialogue_layer.advanced.disconnect(_on_advance)
	gamestate.dialogue_layer.hide()
	signalbus.dialogue_ended.emit()
	_current_event_key = ""
