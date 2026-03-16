extends Node

func _ready() -> void:
	print("Blank level is quitting...")
	await get_tree().create_timer(0.1, true).timeout
	get_tree().quit()
