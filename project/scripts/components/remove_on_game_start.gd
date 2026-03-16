class_name RemoveOnGameStart
extends Node

func _ready() -> void:
	await signalbus.game_started
	get_parent().queue_free()
