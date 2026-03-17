extends Area3D

@onready var _collision: CollisionShape3D = $CollisionShape3D
@onready var _debug_mesh: MeshInstance3D = $DebugMesh

var _input: PlayerInput
var _last_input = false


func _ready() -> void:
	_input = gamestate.player_input
	_collision.shape = _debug_mesh.mesh.create_convex_shape()


func _process(_delta: float) -> void:
	if _input.interact:
		if not _last_input:
			fire_sonar()
		_last_input = true
	else:
		_last_input = false


#
# Detects the collision of the sonar cone with the entities and 
# highlights the entities that are hit by the sonar cone in bright red.
#
func fire_sonar() -> void:
	print("attempting to fire sonar")
	var overlapped_bodies: Array[Node3D] = get_overlapping_bodies()
	print("overlapped bodies: ", overlapped_bodies)
	for body in overlapped_bodies:
		print("body is:", body)
		body.highlight()
