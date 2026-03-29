extends CharacterBody3D

const net_scene := preload("res://scenes/levels/fishing/fishing_net_sprite.tscn")

@export var move_speed := 8.0
@export var turn_speed := 2.0
@export var lake_radius := 30.0
@export var health := 100.0 # TODO: Make flexible to persistent upgrades.

@onready var _camera: Camera3D = $Camera3D
@onready var net_arc: MeshInstance3D = $NetArc

const NET_PARABOLA_SPEED: float = 0.15

var _input: PlayerInput
var _cam_origin_pitch: float
var sonar_cooldown_ticks: int = 0
var sonar_cooldown_max: int = 120
var net_local_offset: Vector3 = Vector3.ZERO
var net_debug_mesh: MeshInstance3D = null

var cumumative_forward_fishing_net_distance: float = 0.0

enum NetState { NONE, AIMING, FIRING_NET, UNDER_WATER, REELING_IN_NET }
var net_state: NetState = NetState.NONE

# Net projectile
var _net_projectile: Area3D = null
var _net_fire_start: Vector3
var _net_fire_end: Vector3
var _net_fire_t: float = 0.0
const NET_FIRE_DURATION: float = 0.6
const NET_ARC_HEIGHT: float = 3.0
const NET_UNDERWATER_DURATION: float = 2.0
const NET_REEL_DURATION: float = 0.8
const SPHERE_RADIUS: float = 9.6
const SPHERE_HEIGHT: float = 9.6 * 2.0

# Reel-in state
var _reel_t: float = 0.0
var _reel_start: Vector3
var _caught_fish: Node3D = null


func _ready() -> void:
	_input = gamestate.player_input
	_cam_origin_pitch = _camera.rotation_degrees.x


func _physics_process(delta: float) -> void:
	# do nothing if dialogue is playing
	if gamestate.is_dialogue_playing:
		return

	if sonar_cooldown_ticks > 0:
		sonar_cooldown_ticks -= 1

	if Input.is_action_just_released("net_arm"):
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
		if Input.is_action_just_pressed("netting"):
			fire_net()

	if net_state == NetState.FIRING_NET or net_state == NetState.UNDER_WATER:
		_process_net_projectile(delta)

	if net_state == NetState.REELING_IN_NET:
		_process_reeling_in_net(delta)


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


func move_boat(x_move: float, y_move: float, delta: float) -> void:
	rotation.y -= x_move * turn_speed * delta

	var forward := -transform.basis.z
	position += forward * (-y_move) * move_speed * delta

	var pos_flat := get_flat_position()
	position.x = pos_flat.x
	position.z = pos_flat.y

	_camera.rotation_degrees.x = clampf(
		_cam_origin_pitch,
		-90.0,
		-20.0,
	)
	#_camera.rotation_degrees.y = y_move


func _is_over_water(world_pos: Vector3) -> bool:
	var water: MeshInstance3D = get_tree().get_first_node_in_group("WaterSurface")
	if not water:
		return false
	var aabb: AABB = water.get_aabb()
	var local_pos: Vector3 = water.to_local(world_pos)
	return aabb.has_point(Vector3(local_pos.x, aabb.position.y + aabb.size.y * 0.5, local_pos.z))


func aim_net() -> void:
	if net_state == NetState.FIRING_NET:
		return

	var candidate_offset := net_local_offset
	candidate_offset.z = -(cumumative_forward_fishing_net_distance + NET_PARABOLA_SPEED)
	var candidate_world: Vector3 = global_transform * candidate_offset
	candidate_world.y = global_position.y

	if _is_over_water(candidate_world):
		cumumative_forward_fishing_net_distance += NET_PARABOLA_SPEED
	net_local_offset.z = -cumumative_forward_fishing_net_distance

	var net_world_pos: Vector3 = global_transform * net_local_offset
	net_world_pos.y = global_position.y

	if not net_debug_mesh:
		set_net_debug_mesh(null)
	net_debug_mesh.global_position = net_world_pos

	net_arc.global_transform = Transform3D.IDENTITY
	net_arc.mesh = net_arc.call("calculate_net_path", global_position, net_world_pos)


func retract_net() -> void:
	net_state = NetState.NONE
	clear_net_debug_mesh()
	if _net_projectile:
		_net_projectile.queue_free()
		_net_projectile = null
	net_local_offset = Vector3.ZERO
	cumumative_forward_fishing_net_distance = 0.0
	net_arc.mesh = null


func set_net_debug_mesh(_mesh: MeshInstance3D) -> void:
	net_debug_mesh = MeshInstance3D.new()
	net_debug_mesh.mesh = CylinderMesh.new()
	net_debug_mesh.set_surface_override_material(0, StandardMaterial3D.new())
	get_tree().root.add_child(net_debug_mesh)
	net_debug_mesh.position = global_transform * net_local_offset


func clear_net_debug_mesh() -> void:
	if net_debug_mesh:
		net_debug_mesh.queue_free()
		net_debug_mesh = null


func fire_net() -> void:
	net_state = NetState.FIRING_NET

	_net_fire_start = global_position
	_net_fire_end = global_transform * net_local_offset
	_net_fire_end.y = global_position.y
	_net_fire_t = 0.0

	if _net_projectile:
		_net_projectile.queue_free()

	_net_projectile = Area3D.new()

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = SPHERE_RADIUS
	col.shape = shape
	_net_projectile.add_child(col)

	if false:
		var mesh_inst := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = SPHERE_RADIUS
		sphere.height = SPHERE_HEIGHT
		mesh_inst.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.9, 0.85, 0.6)
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mesh_inst.set_surface_override_material(0, mat)
		_net_projectile.add_child(mesh_inst)

	var net_sprite: FishingNetSprite = net_scene.instantiate()
	net_sprite.rotate(Vector3.UP, global_rotation.y)
	_net_projectile.add_child(net_sprite)

	_net_projectile.monitoring = true
	get_tree().root.add_child(_net_projectile)
	_net_projectile.global_position = _net_fire_start


func _check_net_overlap() -> void:
	if not _net_projectile or net_state != NetState.UNDER_WATER:
		return
	for body: Node3D in _net_projectile.get_overlapping_bodies():
		if body == self:
			continue
		if body is CharacterBody3D:
			print("gottem!")
			_caught_fish = body
			_caught_fish.set_physics_process(false)
			_reel_start = body.global_position
			_reel_t = 0.0
			net_state = NetState.REELING_IN_NET
			return


func _process_net_projectile(delta: float) -> void:
	if (net_state != NetState.FIRING_NET and net_state != NetState.UNDER_WATER) or not _net_projectile:
		return

	if net_state == NetState.FIRING_NET:
		_net_fire_t += delta / NET_FIRE_DURATION
		if _net_fire_t >= 1.0:
			print("going under water!")
			_net_fire_t = 0.0
			#_on_net_landed()
			net_state = NetState.UNDER_WATER
			# Now set the new end to be the sea floor below the net's end position.
			_net_fire_start = _net_fire_end
			_net_fire_end = _net_fire_end - Vector3(0.0, 10.0, 0.0)
	elif net_state == NetState.UNDER_WATER:
		_net_fire_t += delta / NET_UNDERWATER_DURATION
		_check_net_overlap()
		if net_state != NetState.UNDER_WATER:
			return

	var linear: Vector3 = _net_fire_start.lerp(_net_fire_end, _net_fire_t)
	var arc_y: float = _net_fire_start.y + 4.0 * NET_ARC_HEIGHT * _net_fire_t * (1.0 - _net_fire_t)
	# This should be the linear interpolation between the start and end positions.
	if net_state == NetState.UNDER_WATER:
		arc_y = _net_fire_start.y
		var linear_underwater: Vector3 = _net_fire_start.lerp(_net_fire_end - Vector3(0.0, 10.0, 0.0), _net_fire_t)
		arc_y = linear_underwater.y

	_net_projectile.global_position = Vector3(linear.x, arc_y, linear.z)


func _process_reeling_in_net(_delta: float) -> void:
	# TODO: Some animation of maybe water splashes implying 'reeling in' a fish.
	var fish := _caught_fish
	_caught_fish = null
	retract_net()
	signalbus.fish_caught.emit(fish)
