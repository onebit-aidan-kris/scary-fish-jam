extends Node

@export var has_met_walsh := false
@export var has_met_jeff := false
@export var has_met_brad := false

@export var player: HumanCharacter
@export var walsh: HumanCharacter
@export var jeff: HumanCharacter
@export var brad: HumanCharacter


func _ready() -> void:
	assert(player)
	assert(walsh)
	assert(jeff)
	assert(brad)


func face(src: HumanCharacter, target: HumanCharacter) -> void:
	print(src, target)
	var diff := (target.position - src.position).normalized()
	print(diff)
	src.set_direction_vector(diff)


func met_walsh() -> void:
	has_met_walsh = true
	walsh_to_boat()


func met_jeff() -> void:
	has_met_jeff = true
	print("player met Jeff")


func walsh_to_boat() -> void:
	print("walsh to boat")
	var ap = walsh.find_child("DockToBoatPath")
	if ap:
		print("DockToBoatPath found")
		ap.activate()
	else:
		print("AStar2DPath not found")

func brad_intro_met() -> void:
	has_met_brad = true
