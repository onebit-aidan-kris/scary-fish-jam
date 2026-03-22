extends Node

func _ready() -> void:
	get_parent().interacted.connect(_test)


func _test() -> void:
	print("Interacted!")
