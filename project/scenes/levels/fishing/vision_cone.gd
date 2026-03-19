extends Node3D

signal boat_detected(boat: Node3D)
signal boat_lost(boat: Node3D)

@export var detection_radius := 15.0
@export var cone_half_angle_deg := 45.0

var _tracked_boat: Node3D = null


func _physics_process(_delta: float) -> void:
	var fish := get_parent() as CharacterBody3D
	var boat: Node3D = get_tree().get_first_node_in_group("player")
	if not boat:
		return

	var to_boat := boat.global_position - fish.global_position
	var dist := to_boat.length()

	if dist > detection_radius:
		if _tracked_boat:
			_tracked_boat = null
			boat_lost.emit(boat)
		return

	var forward := -fish.global_transform.basis.z
	var angle := rad_to_deg(forward.angle_to(to_boat.normalized()))

	if angle <= cone_half_angle_deg:
		if not _tracked_boat:
			_tracked_boat = boat
			boat_detected.emit(boat)
	else:
		if _tracked_boat:
			_tracked_boat = null
			boat_lost.emit(boat)
