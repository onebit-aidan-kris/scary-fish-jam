class_name DebugRotate
extends Node

@export var speed := 1.0

@onready var parent: Node3D = get_parent()


func _physics_process(delta: float) -> void:
	parent.rotate(Vector3.UP, speed * delta)
