class_name DebugSpriteDemo
extends Node

@export var anim_time_s := 1.0



@onready var parent: AnimatedSprite3D = get_parent()


func _ready() -> void:
	assert(parent)
	_anim_loop()


func _anim_loop() -> void:
	var anim_names := parent.sprite_frames.get_animation_names()
	
	var i = 0
	while true:
		parent.play(anim_names[i])
		
		await get_tree().create_timer(anim_time_s).timeout
		i = (i + 1) % anim_names.size()
