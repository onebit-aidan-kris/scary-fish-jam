extends CharacterBody3D

@export var patrol_path: Node3D
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var child_mesh: MeshInstance3D
var is_highlighted: bool = false

var highlight_circle: MeshInstance3D
var highlight_timer_ticks = 120 # Assume 60fps?

func _ready() -> void:
	child_mesh = get_node("MeshInstance3D")


func _process(delta: float) -> void:
	if is_highlighted:
		if (highlight_circle.mesh as SphereMesh).radius > 0:
			(highlight_circle.mesh as SphereMesh).radius -= 0.003
		else:
			is_highlighted = false
			highlight_circle.queue_free()
			highlight_circle = null
			return

# Highlights the fish in bright red.
func highlight() -> void:
	if is_highlighted:
		return
	is_highlighted = true
	# Calculate the y intersection above the fish with the WaterSurface
	var water_surface: MeshInstance3D = get_tree().get_first_node_in_group("WaterSurface")
	print("water surface is: ", water_surface)
	var water_surface_pos: Vector3 = water_surface.global_position
	var fish_pos: Vector3 = global_position
	var fish_height: float = fish_pos.y
	var water_surface_height: float = water_surface_pos.y
	var layer_offset: float = 1 # To ensure circle is visible above water surface (barely)
	var intersection_y: float = fish_height + water_surface_height + layer_offset
	print("intersection_y is: ", intersection_y)


	#Draw a red circle at this intersection point
	highlight_circle = MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 3
	sphere_mesh.height = 3
	highlight_circle.mesh = sphere_mesh
	# Set the material to red
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.RED
	mat.emission_energy_multiplier = 5.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	highlight_circle.set_surface_override_material(0, mat)

	get_tree().root.add_child(highlight_circle)
	highlight_circle.global_position = Vector3(fish_pos.x, intersection_y, fish_pos.z)
	
	print("highlight_circle is at position: ", highlight_circle.global_position)
	
	#(child_mesh.get_surface_override_material(0) as StandardMaterial3D).albedo_color = Color.RED
