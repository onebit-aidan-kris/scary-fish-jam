extends Node3D

@export var move_speed := 8.0
@export var turn_speed := 2.0
@export var lake_radius := 30.0

@onready var _camera: Camera3D = $Camera3D

var _input: PlayerInput
var _cam_origin_pitch: float


func _ready() -> void:
	_input = gamestate.player_input
	_cam_origin_pitch = _camera.rotation_degrees.x


func _physics_process(delta: float) -> void:
	if not _input:
		return

	rotation.y -= _input.move.x * turn_speed * delta

	var forward := -transform.basis.z
	position += forward * (-_input.move.y) * move_speed * delta

	var pos_flat := Vector2(position.x, position.z)
	if pos_flat.length() > lake_radius:
		pos_flat = pos_flat.normalized() * lake_radius
		position.x = pos_flat.x
		position.z = pos_flat.y


func _process(_delta: float) -> void:
	if _input:
		_camera.rotation_degrees.x = clampf(
			_cam_origin_pitch + _input.look.x, -89.0, 10.0
		)
		_camera.rotation_degrees.y = _input.look.y
