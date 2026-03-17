extends Node3D

const LAKE_RADIUS := 30.0
const SEA_FLOOR_Y := -8.0
const NUM_OBJECTS := 80
const RNG_SEED := 42


func _ready() -> void:
	_populate_sea_floor()


func _populate_sea_floor() -> void:
	var parent := $SeaFloorObjects
	var rng := RandomNumberGenerator.new()
	rng.seed = RNG_SEED

	for _i in NUM_OBJECTS:
		var angle := rng.randf() * TAU
		# sqrt for uniform distribution across the circular area
		var dist := sqrt(rng.randf()) * (LAKE_RADIUS - 2.0)
		var pos := Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)

		var mesh_inst := MeshInstance3D.new()
		var mat := StandardMaterial3D.new()

		var kind := rng.randi() % 4
		match kind:
			0:
				var m := BoxMesh.new()
				var sy := rng.randf_range(0.3, 1.5)
				m.size = Vector3(
					rng.randf_range(0.5, 2.0), sy, rng.randf_range(0.5, 2.0)
				)
				mesh_inst.mesh = m
				pos.y = SEA_FLOOR_Y + sy * 0.5
				mat.albedo_color = Color(
					rng.randf_range(0.3, 0.5),
					rng.randf_range(0.3, 0.45),
					rng.randf_range(0.25, 0.4),
				)
			1:
				var m := CylinderMesh.new()
				m.top_radius = rng.randf_range(0.05, 0.15)
				m.bottom_radius = rng.randf_range(0.1, 0.2)
				var h := rng.randf_range(1.0, 4.0)
				m.height = h
				mesh_inst.mesh = m
				pos.y = SEA_FLOOR_Y + h * 0.5
				mat.albedo_color = Color(
					rng.randf_range(0.1, 0.25),
					rng.randf_range(0.4, 0.65),
					rng.randf_range(0.1, 0.2),
				)
			2:
				var m := SphereMesh.new()
				var r := rng.randf_range(0.3, 1.0)
				m.radius = r
				m.height = r * 2.0
				mesh_inst.mesh = m
				pos.y = SEA_FLOOR_Y + r
				mat.albedo_color = Color(
					rng.randf_range(0.6, 0.9),
					rng.randf_range(0.2, 0.5),
					rng.randf_range(0.2, 0.4),
				)
			3:
				var m := BoxMesh.new()
				var sy := rng.randf_range(0.1, 0.3)
				m.size = Vector3(
					rng.randf_range(1.0, 3.0), sy, rng.randf_range(1.0, 3.0)
				)
				mesh_inst.mesh = m
				pos.y = SEA_FLOOR_Y + sy * 0.5
				mat.albedo_color = Color(
					rng.randf_range(0.4, 0.55),
					rng.randf_range(0.4, 0.5),
					rng.randf_range(0.35, 0.45),
				)

		mesh_inst.set_surface_override_material(0, mat)
		mesh_inst.position = pos
		mesh_inst.rotation.y = rng.randf() * TAU
		parent.add_child(mesh_inst)
