extends Node3D

signal boat_detected(boat: Node3D)
signal boat_lost(boat: Node3D)

@export var detection_radius := 15.0
@export var cone_half_angle_deg := 45.0

const DEBUG_SEGMENTS := 16

var _tracked_boat: Node3D = null
var _debug_mesh: MeshInstance3D
var _mat_idle: StandardMaterial3D
var _mat_alert: StandardMaterial3D


func _ready() -> void:
	_mat_idle = StandardMaterial3D.new()
	_mat_idle.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_idle.albedo_color = Color(0.2, 0.8, 0.2, 0.25)
	_mat_idle.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_idle.cull_mode = BaseMaterial3D.CULL_DISABLED

	_mat_alert = StandardMaterial3D.new()
	_mat_alert.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_alert.albedo_color = Color(1.0, 0.1, 0.1, 0.45)
	_mat_alert.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat_alert.cull_mode = BaseMaterial3D.CULL_DISABLED

	_debug_mesh = MeshInstance3D.new()
	_debug_mesh.mesh = _build_cone_mesh()
	_debug_mesh.set_surface_override_material(0, _mat_idle)
	add_child(_debug_mesh)


func _build_cone_mesh() -> ArrayMesh:
	var half_angle_rad := deg_to_rad(cone_half_angle_deg)
	var base_radius := detection_radius * sin(half_angle_rad)
	var length := detection_radius * cos(half_angle_rad)

	var tip := Vector3.ZERO
	var raw: Array[Vector3] = []

	for i in DEBUG_SEGMENTS:
		var a0 := TAU * i / DEBUG_SEGMENTS
		var a1 := TAU * (i + 1) / DEBUG_SEGMENTS
		var b0 := Vector3(sin(a0) * base_radius, cos(a0) * base_radius, -length)
		var b1 := Vector3(sin(a1) * base_radius, cos(a1) * base_radius, -length)
		raw.append_array([tip, b0, b1, Vector3.ZERO, b1, b0])

	var vertices := PackedVector3Array(raw)

	var arr := Array()
	var _resized := arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = vertices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return mesh


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
			_debug_mesh.set_surface_override_material(0, _mat_idle)
		return

	var forward := -fish.global_transform.basis.z
	var angle := rad_to_deg(forward.angle_to(to_boat.normalized()))

	if angle <= cone_half_angle_deg:
		if not _tracked_boat:
			_tracked_boat = boat
			boat_detected.emit(boat)
			_debug_mesh.set_surface_override_material(0, _mat_alert)
	else:
		if _tracked_boat:
			_tracked_boat = null
			boat_lost.emit(boat)
			_debug_mesh.set_surface_override_material(0, _mat_idle)

	if _tracked_boat:
		look_at(boat.global_position, Vector3.UP)
