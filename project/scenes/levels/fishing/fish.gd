extends CharacterBody3D

@export var patrol_path: NodePath
@export var swim_speed := 3.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var patrol_behavior: Node = $PatrolBehavior

var child_mesh: MeshInstance3D
var highlight_circle: MeshInstance3D


func _ready() -> void:
	child_mesh = get_node("MeshInstance3D")
	var path_node := get_node(patrol_path)
	patrol_behavior.nav_agent = nav_agent
	patrol_behavior.set_patrol_nodes(path_node)


func _physics_process(_delta: float) -> void:
	var next_pos := nav_agent.get_next_path_position()
	var direction := (next_pos - global_position).normalized()
	velocity = direction * swim_speed

	if velocity.length_squared() > 0.001:
		var target_pos := global_position + velocity.normalized()
		look_at(target_pos, Vector3.UP)

	var _collided := move_and_slide()


func _process(_delta: float) -> void:
	if highlight_circle and (highlight_circle.mesh as SphereMesh).radius > 0:
		(highlight_circle.mesh as SphereMesh).radius -= 0.003
	elif highlight_circle:
		highlight_circle.queue_free()
		highlight_circle = null


func highlight() -> void:
	if highlight_circle:
		return
	var water_surface: MeshInstance3D = get_tree().get_first_node_in_group("WaterSurface")
	var water_surface_pos: Vector3 = water_surface.global_position
	var fish_pos: Vector3 = global_position
	var layer_offset := 1.0
	var intersection_y: float = fish_pos.y + water_surface_pos.y + layer_offset

	highlight_circle = MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 3
	sphere_mesh.height = 3
	highlight_circle.mesh = sphere_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.RED
	mat.emission_energy_multiplier = 5.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	highlight_circle.set_surface_override_material(0, mat)

	get_tree().root.add_child(highlight_circle)
	highlight_circle.global_position = Vector3(fish_pos.x, intersection_y, fish_pos.z)
