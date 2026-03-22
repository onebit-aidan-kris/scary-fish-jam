extends Node

@export var has_met_walsh := false

@export var player: HumanCharacter
@export var walsh: HumanCharacter


func _ready() -> void:
	assert(player)
	assert(walsh)


func face(src: HumanCharacter, target: HumanCharacter) -> void:
	print(src, target)
	var diff := (target.position - src.position).normalized()
	print(diff)
	src.set_direction_vector(diff)


func met_walsh() -> void:
	has_met_walsh = true
	print("player met Walsh")
