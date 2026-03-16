class_name DialogueLayer
extends CanvasLayer

@onready var _dialogue_label: RichTextLabel = %DialogueLabel
@onready var _choices_container: Container = %Choices
@onready var _button_template: Button = %ButtonTemplate
@onready var _advance_button: Button = %AdvanceHint
@onready var _speaker_container: Container = %SpeakerContainer
@onready var _speaker_label: Label = %SpeakerLabel

signal advanced(index: int)


func _ready() -> void:
	assert(_dialogue_label)
	assert(_choices_container)
	assert(_button_template)
	assert(_advance_button)
	assert(_speaker_label)
	assert(_speaker_container)

	util.aok(_advance_button.pressed.connect(_on_choice_selected.bind(0)))

	_button_template.hide()
	hide()


func _process(_delta: float) -> void:
	pass


func _clear() -> void:
	_speaker_container.hide()
	_advance_button.hide()
	_dialogue_label.clear()
	_choices_container.hide()
	for btn: Button in _choices_container.get_children():
		if btn.visible:
			btn.queue_free()


func render(speaker: String, text: Array[String], choices: Array[String]) -> void:
	_clear()

	if speaker:
		_speaker_label.text = speaker
		_speaker_container.show()

	for line in text:
		_dialogue_label.append_text(line)
		_dialogue_label.newline()

	if choices:
		_choices_container.show()
		for i in choices.size():
			var choice := choices[i]
			var btn: Button = _button_template.duplicate()
			btn.text = choice
			util.aok(btn.pressed.connect(_on_choice_selected.bind(i)))
			btn.show()
			_choices_container.add_child(btn)
			if i == 0:
				btn.grab_focus()
	else:
		_advance_button.show()
		_advance_button.grab_focus()

	show()


func _on_choice_selected(index: int) -> void:
	advanced.emit(index)
