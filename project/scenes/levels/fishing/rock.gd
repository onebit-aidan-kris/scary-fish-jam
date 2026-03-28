@tool
extends StaticBody3D

func _ready() -> void:
	var sprite: Sprite3D = $RockSprite
	sprite.frame = randi_range(0, sprite.hframes * sprite.vframes - 1)
