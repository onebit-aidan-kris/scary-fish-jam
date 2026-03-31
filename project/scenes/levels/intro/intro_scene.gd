extends Node

@onready var _dialogue: DialogueEntry = $DialogueEntry


func _ready() -> void:
	await signalbus.game_started
	_dialogue.start()
	await signalbus.dialogue_ended
	gamestate.screen_fade.fade_to_scene("res://scenes/levels/town/town_level.tscn")
