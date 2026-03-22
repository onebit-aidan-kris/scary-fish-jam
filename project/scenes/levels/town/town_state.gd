extends Node

@export var has_met_walsh := false
@export var has_met_jeff := false

@export var player: HumanCharacter
@export var walsh: HumanCharacter
@export var jeff: HumanCharacter


func _ready() -> void:
	assert(player)
	assert(walsh)
	assert(jeff)


func face(src: HumanCharacter, target: HumanCharacter) -> void:
	print(src, target)
	var diff := (target.position - src.position).normalized()
	print(diff)
	src.set_direction_vector(diff)


func met_walsh() -> void:
	has_met_walsh = true
	print("player met Walsh")


func met_jeff() -> void:
	has_met_jeff = true
	print("player met Jeff")
