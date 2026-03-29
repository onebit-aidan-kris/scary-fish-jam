class_name FishCountCondition
extends Node

@export var required_count := 1
@export var fish_type := "any"

var current_count := 0


func is_satisfied() -> bool:
	return current_count >= required_count


func on_fish_caught(fish: Node3D) -> void:
	if fish_type == "any" or (fish is FishEntity and fish.fish_type == fish_type):
		current_count += 1
