extends CharacterBody3D

@export var patrol_path: Node3D
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var child_mesh: MeshInstance3D

func _ready() -> void:
	child_mesh = get_node("MeshInstance3D")


# Highlights the fish in bright red.
func highlight() -> void:
	var mat := child_mesh.get_surface_override_material(0) as StandardMaterial3D
	mat.albedo_color = Color.RED
	mat.emission_energy_multiplier = 3.0

	print("highlighting fish: ", self )
	print("child_mesh is: ", child_mesh)
	print("override count is: ", child_mesh.get_surface_override_material_count())
	print("override mat is: ", child_mesh.get_surface_override_material(0))
	#(child_mesh.get_surface_override_material(0) as StandardMaterial3D).albedo_color = Color.RED
