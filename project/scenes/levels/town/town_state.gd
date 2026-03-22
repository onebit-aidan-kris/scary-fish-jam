extends Node

@export var has_met_walsh := false


func met_walsh() -> void:
	has_met_walsh = true
	print("player met Walsh")
