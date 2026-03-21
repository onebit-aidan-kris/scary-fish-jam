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
var net_local_offset: Vector3 = Vector3.ZERO
var net_debug_mesh: MeshInstance3D = null

enum NetState {NONE, AIMING, NETTING, NETTED}
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
			move_boat(_input.move.x, _input.move.y, delta)
		if Input.is_action_just_pressed("net_arm"):
			net_state = NetState.AIMING
			net_local_offset = Vector3(0.0, 0.0, -4.0)
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


func get_flat_position() -> Vector2:
	var pos_flat := Vector2(position.x, position.z)
	if pos_flat.length() > lake_radius:
		pos_flat = pos_flat.normalized() * lake_radius
	return pos_flat

func move_boat(x_move, y_move, delta: float) -> void:
	rotation.y -= x_move * turn_speed * delta

	var forward := -transform.basis.z
	position += forward * (-y_move) * move_speed * delta

	var pos_flat := get_flat_position()
	position.x = pos_flat.x
	position.z = pos_flat.y

	_camera.rotation_degrees.x = clampf(
		_cam_origin_pitch + x_move,
		-90.0,
		10.0,
	)
	_camera.rotation_degrees.y = y_move


func aim_net() -> void:
	#
	# -- Delay when swapping between 2 modes. (reduce jerkiness)
	# -- Support WASD (and HOLDING WASD!) due to webviews / mouse view flakiness.
	# -- Replace code here as needed
	# 
	# 
	var should_move_left: bool = Input.is_action_pressed("move_left")
	var should_move_right: bool = Input.is_action_pressed("move_right")


	var next_left_right_position: int = 0
	var next_forward_position: int = 0

	if should_move_left:
		next_left_right_position -= 1
	if should_move_right:
		next_left_right_position += 1

	next_forward_position += 1

	var x_move: float = float(next_left_right_position)
	var dummy_delta: float = Engine.time_scale / float(Engine.physics_ticks_per_second)
	move_boat(x_move, 0, dummy_delta)


	# If moving left or right, move the boat itself left or right.
	if next_left_right_position != 0:
		pass


	net_local_offset.x += x_move * 0.1

	var net_world_pos: Vector3 = global_transform * net_local_offset
	net_world_pos.y = global_position.y

	if not net_debug_mesh:
		set_net_debug_mesh(net_debug_mesh)
	else:
		net_debug_mesh.global_position = net_world_pos

	net_arc.global_transform = Transform3D.IDENTITY
	net_arc.mesh = net_arc.call("calculate_net_path", global_position, net_world_pos)


func retract_net() -> void:
	net_state = NetState.NONE
	clear_net_debug_mesh()
	net_local_offset = Vector3.ZERO
	net_arc.mesh = null


func set_net_debug_mesh(_mesh: MeshInstance3D) -> void:
	net_debug_mesh = MeshInstance3D.new()
	net_debug_mesh.mesh = CylinderMesh.new()
	net_debug_mesh.set_surface_override_material(0, StandardMaterial3D.new())
	net_debug_mesh.global_position = global_transform * net_local_offset
	get_tree().root.add_child(net_debug_mesh)


func clear_net_debug_mesh() -> void:
	if net_debug_mesh:
		net_debug_mesh.queue_free()
		net_debug_mesh = null
