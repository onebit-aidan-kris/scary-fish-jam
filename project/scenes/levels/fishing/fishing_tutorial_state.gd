extends Node

var sonar_explanation_finished := false
var sonar_highlight_explanation_finished := false

@onready var dialogue_entry: DialogueEntry = $DialogueEntryTutorial


func _ready() -> void:
	assert(dialogue_entry, "DialogueEntryTutorial node not found")
	util.aok(signalbus.sonar_highlight.connect(_on_sonar_highlight))


func post_sonar_explanation() -> void:
	print("post sonar")
	sonar_explanation_finished = true


func _on_sonar_highlight(position: Vector3) -> void:
	print("!!! firing sonar highlight: ")
	if sonar_highlight_explanation_finished:
		return
	sonar_highlight_explanation_finished = true
	print("sonar highlight: ", position)
	dialogue_entry.jump_to_event("post_sonar")
