extends Area2D

@warning_ignore("unused_signal")
signal interacted

const _fishing_scene_file := "uid://dku1y8g8g5cu1" # fishing_level.tscn


func _ready() -> void:
	Interactable.register(self, _on_interact)


func _on_interact() -> void:
	util.aok(get_tree().change_scene_to_file(_fishing_scene_file))
