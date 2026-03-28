extends Node3D

const LAKE_RADIUS := 30.0
const SEA_FLOOR_Y := -8.0
const NUM_OBJECTS := 80
const RNG_SEED := 42

@export_file("*.tscn") var next_level_scene: String

# Used for rendering sonar highlights
var _highlight_circles: Array[MeshInstance3D] = []
var _highlight_mat: StandardMaterial3D
var fish_caught: Array[Node3D] = []


func _ready() -> void:
	gamestate.unpause()
	_highlight_mat = StandardMaterial3D.new()
	_highlight_mat.albedo_color = Color.RED
	_highlight_mat.emission_energy_multiplier = 5.0
	_highlight_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	util.aok(signalbus.sonar_highlight.connect(_on_sonar_highlight))
	util.aok(signalbus.fish_caught.connect(add_fish_caught))
	util.aok(signalbus.level_won.connect(_on_level_won))
	


func _process(_delta: float) -> void:
	var i := 0
	while i < _highlight_circles.size():
		var circle := _highlight_circles[i]
		var disc := circle.mesh as CylinderMesh
		if disc.top_radius > 0.0:
			disc.top_radius -= 0.003
			disc.bottom_radius -= 0.003
			i += 1
		else:
			circle.queue_free()
			_highlight_circles.remove_at(i)


func _on_sonar_highlight(fish_position: Vector3) -> void:
	var water_surface: MeshInstance3D = get_tree().get_first_node_in_group("WaterSurface")
	var surface_y: float = water_surface.global_position.y if water_surface else 0.0
	var highlight_y: float = surface_y + 1.0

	var circle := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 3.0
	disc.bottom_radius = 3.0
	disc.height = 0.05
	circle.mesh = disc
	circle.set_surface_override_material(0, _highlight_mat)

	add_child(circle)
	circle.global_position = Vector3(fish_position.x, highlight_y, fish_position.z)
	_highlight_circles.append(circle)


func add_fish_caught(fish: Node3D) -> void:
	fish_caught.append(fish)
	fish.queue_free()
	print("fish caught! : ", fish_caught.size())


func _on_level_won() -> void:
	print("Level won! Transitioning to: ", next_level_scene)
	if next_level_scene:
		util.aok(get_tree().change_scene_to_file(next_level_scene))
	else:
		print("No next level scene configured")
