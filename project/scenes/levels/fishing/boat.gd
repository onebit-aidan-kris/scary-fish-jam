extends CharacterBody3D

@export var move_speed := 8.0
@export var turn_speed := 2.0
@export var lake_radius := 30.0
@export var health := 100.0 # TODO: Make flexible to persistent upgrades.

@onready var _camera: Camera3D = $Camera3D

var _input: PlayerInput
var _cam_origin_pitch: float

var sonar_cooldown_ticks: int = 0
var sonar_cooldown_max: int = 120


func _ready() -> void:
	_input = gamestate.player_input
	_cam_origin_pitch = _camera.rotation_degrees.x


func _physics_process(delta: float) -> void:
	if sonar_cooldown_ticks > 0:
		sonar_cooldown_ticks -= 1

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
			_cam_origin_pitch + _input.look.x,
			-89.0,
			10.0,
		)
		_camera.rotation_degrees.y = _input.look.y


func is_sonar_ready() -> bool:
	return sonar_cooldown_ticks <= 0


func trigger_sonar() -> void:
	sonar_cooldown_ticks = sonar_cooldown_max


func receive_damage(damage_amount: int) -> void:
	print("Player received damage: ", damage_amount)
	health -= damage_amount
	if health <= 0:
		print("Player is dead!")
