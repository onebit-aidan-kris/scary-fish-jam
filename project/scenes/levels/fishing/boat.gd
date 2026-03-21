extends CharacterBody3D

@export var move_speed := 8.0
@export var turn_speed := 2.0
@export var lake_radius := 30.0
@export var health := 100.0 # TODO: Make flexible to persistent upgrades.

@onready var _camera: Camera3D = $Camera3D
@onready var net_arc: MeshInstance3D = $NetArc

var _input: PlayerInput
var _cam_origin_pitch: float

var sonar_cooldown_ticks: int = 0
var sonar_cooldown_max: int = 120
var net_position: Vector3 = Vector3.ZERO
var net_debug_mesh: MeshInstance3D = null

enum NetState { NONE, AIMING, NETTING, NETTED }
var net_state: NetState = NetState.NONE


func _ready() -> void:
	_input = gamestate.player_input
	_cam_origin_pitch = _camera.rotation_degrees.x


func _physics_process(delta: float) -> void:
	if sonar_cooldown_ticks > 0:
		sonar_cooldown_ticks -= 1

	if net_state == NetState.AIMING and Input.is_action_just_released("net_arm"):
		print('retracting net')
		retract_net()

	if net_state == NetState.NONE:
		if _input:
			move_boat(delta)
		if Input.is_action_just_pressed("net_arm"):
			net_state = NetState.AIMING
		return

	if net_state == NetState.AIMING:
		aim_net()


func is_sonar_ready() -> bool:
	return sonar_cooldown_ticks <= 0


func trigger_sonar() -> void:
	sonar_cooldown_ticks = sonar_cooldown_max


func receive_damage(damage_amount: int) -> void:
	print("Player received damage: ", damage_amount)
	health -= damage_amount
	if health <= 0:
		print("Player is dead!")


func move_boat(delta: float) -> void:
	rotation.y -= _input.move.x * turn_speed * delta

	var forward := -transform.basis.z
	position += forward * (-_input.move.y) * move_speed * delta

	var pos_flat := Vector2(position.x, position.z)
	if pos_flat.length() > lake_radius:
		pos_flat = pos_flat.normalized() * lake_radius
		position.x = pos_flat.x
		position.z = pos_flat.y

	_camera.rotation_degrees.x = clampf(
		_cam_origin_pitch + _input.look.x,
		-90.0,
		10.0,
	)
	_camera.rotation_degrees.y = _input.look.y


func aim_net() -> void:
	if not net_position:
		net_position = global_position + global_transform.basis.z * 10.0

		net_debug_mesh = MeshInstance3D.new()
		net_debug_mesh.mesh = CylinderMesh.new()
		net_debug_mesh.set_surface_override_material(0, StandardMaterial3D.new())
		net_debug_mesh.global_position = net_position
		add_child(net_debug_mesh)

	#
	# Will change net's target position on the water based on mouse change position.
	# goal: get the mouse delta
	#
	var mouse_delta: Vector2 = Input.get_last_mouse_velocity()
	net_position += global_transform.basis.x * mouse_delta.x * 0.1
	net_position += -global_transform.basis.z * mouse_delta.y * 0.1
	net_position.y = global_position.y
	if not net_debug_mesh:
		set_net_debug_mesh(net_debug_mesh)
	else:
		net_debug_mesh.global_position = net_position
	# Ensures  the world-space vertex positions in the arc aren't offset by the boat's own transform
	net_arc.global_transform = Transform3D.IDENTITY
	net_arc.mesh = net_arc.call("calculate_net_path", global_position, net_position)


func retract_net() -> void:
	net_state = NetState.NONE
	clear_net_debug_mesh()
	net_position = Vector3.ZERO


func set_net_debug_mesh(mesh: MeshInstance3D) -> void:
	net_debug_mesh = MeshInstance3D.new()
	net_debug_mesh.mesh = CylinderMesh.new()
	net_debug_mesh.set_surface_override_material(0, StandardMaterial3D.new())
	net_debug_mesh.global_position = net_position
	add_child(net_debug_mesh)


func clear_net_debug_mesh() -> void:
	if net_debug_mesh:
		net_debug_mesh.queue_free()
		net_debug_mesh = null
