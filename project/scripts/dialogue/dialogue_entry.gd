class_name DialogueEntry
extends Node

@export_file("*.json") var json_path: String

@export var entry_name := "start"
@export var auto_start := false

@onready var state := get_parent()

var _dialogue_data := DialogueData.new()
var _current_event_key := ""
var _current_choices: Array[DialogueEvent.DialogueChoice] = []


func _ready() -> void:
	match util.parse_json_file(json_path):
		[var data, OK]:
			var res := gdserde.deserialize_object(_dialogue_data, data)
			res.expect_ok()
			#print(gdserde.serialize_object(_dialogue_data))
		[_, var err]:
			util.aok(util.as_err(err))

	if auto_start:
		call_deferred(&"start")


func start() -> void:
	if _current_event_key:
		stop()

	_current_event_key = entry_name
	util.aok(gamestate.dialogue_layer.advanced.connect(_on_advance))
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


func _start_next_event() -> void:
	if not _current_event_key:
		stop()
		return

	var event: DialogueEvent = _dialogue_data.events[_current_event_key]

	while not event.text and not event.choices:
		_current_event_key = _dialogue_data.get_next(state, _current_event_key)
		if not _current_event_key:
			stop()
			return
		event = _dialogue_data.events[_current_event_key]

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


func _on_advance(index: int) -> void:
	if _current_choices:
		var choice := _current_choices[index]
		if choice.callback.name:
			print(choice.callback.name, choice.callback.args)
			assert(
				state.has_method(choice.callback.name),
				str("State object does not have method: ", choice.callback.name),
			)
			state.callv(choice.callback.name, choice.callback.args)
		_current_event_key = choice.next
	else:
		_current_event_key = _dialogue_data.get_next(state, _current_event_key)

	_start_next_event()


func stop() -> void:
	gamestate.dialogue_layer.advanced.disconnect(_on_advance)
	gamestate.dialogue_layer.hide()
	_current_event_key = ""
