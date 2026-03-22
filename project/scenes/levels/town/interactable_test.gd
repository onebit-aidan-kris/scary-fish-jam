extends Node

func _ready() -> void:
	Interactable.register(get_parent(), _test)


func _test() -> void:
	print("Interacted!")
