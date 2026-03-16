class_name DebugOnly
extends Node

func _ready() -> void:
	if not OS.is_debug_build():
		get_parent().queue_free()
