extends Area2D

@warning_ignore("unused_signal")
signal interacted

@export_file("*.tscn") var fishing_scene_file: String


func _ready() -> void:
	Interactable.register(self, _on_interact)


func _on_interact() -> void:
	gamestate.screen_fade.fade_to_scene(fishing_scene_file)
