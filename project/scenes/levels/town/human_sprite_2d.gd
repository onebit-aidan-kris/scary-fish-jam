@tool
class_name HumanSprite2D
extends AnimatedSprite2D

func _ready() -> void:
	util.aok(animation_changed.connect(_refresh))
	util.aok(sprite_frames_changed.connect(_refresh))
	call_deferred(&"_refresh")


func _refresh() -> void:
	match animation:
		&"walk-e":
			flip_h = true
		_:
			flip_h = false
