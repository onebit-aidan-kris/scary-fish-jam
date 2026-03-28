class_name ScreenFade
extends CanvasLayer

@onready var _rect: ColorRect = $ColorRect

const FADE_DURATION := 0.4


func _ready() -> void:
	_rect.modulate.a = 0.0


func fade_to_scene(scene_path: String) -> void:
	var tween := create_tween()
	tween.tween_property(_rect, "modulate:a", 1.0, FADE_DURATION)
	await tween.finished
	util.aok(get_tree().change_scene_to_file(scene_path))
	await get_tree().process_frame
	var tween2 := create_tween()
	tween2.tween_property(_rect, "modulate:a", 0.0, FADE_DURATION)
