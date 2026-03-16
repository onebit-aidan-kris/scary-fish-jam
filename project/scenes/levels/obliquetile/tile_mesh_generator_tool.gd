@tool
extends Node

@export_tool_button("Generate MeshLibrary", "MeshInstance3D")
var generate_tiles_action := _generate

@export var meshlib_name: String = "test"
@export var collisions: bool
@export var material: Material

@export var tileset_grid_size := Vector2.ONE
@export var tileset_size: Vector2
@export var tile_grass_center: Vector2i
@export var tile_grass_ramp: Vector2i
@export var tile_wall: Vector2i

@onready var parent: Node3D = get_parent()


func _generate() -> void:
	assert(meshlib_name)
	var filepath := str("res://assets/meshlibrary/", meshlib_name, ".meshlib")
	print("Generating MeshLibrary: ", filepath)

	for child in parent.get_children():
		if child is MeshInstance3D:
			child.queue_free()

	var factory := MeshFactory.new()
	factory.tileset_grid_size = tileset_grid_size
	factory.tileset_size = tileset_size

	var meshes: Array[ArrayMesh] = [
		factory.quad(1, 0, 1, tile_grass_center),
		factory.box(1, 0.5, 1, tile_grass_center, tile_wall),
		factory.ramp(1, 0.5, 1, tile_grass_ramp, tile_wall),
		factory.box(1, 1, 1, tile_grass_center, tile_wall),
		factory.ramp(1, 1, 1, tile_grass_ramp, tile_wall),
	]

	var ml := MeshLibrary.new()

	for i in meshes.size():
		_add_lib_mesh(ml, Vector3.RIGHT * i, meshes[i])

	util.aok(ResourceSaver.save(ml, filepath))


class MeshBuilder:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var size := 0


	func _add_point(vert: Vector3, normal: Vector3, uv: Vector2) -> void:
		util.expect_false(verts.push_back(vert))
		util.expect_false(normals.push_back(normal))
		util.expect_false(uvs.push_back(uv))
		size += 1


	func add_quad(
			p0: Vector3,
			p1: Vector3,
			p2: Vector3,
			uv0: Vector2,
			uv1: Vector2,
			uv2: Vector2,
	) -> void:
		var i := size

		var dp1 := p1 - p0
		var dp2 := p2 - p0
		var duv1 := uv1 - uv0
		var duv2 := uv2 - uv0

		var normal := dp2.cross(dp1)

		_add_point(p0, normal, uv0)
		_add_point(p1, normal, uv1)
		_add_point(p2, normal, uv2)
		_add_point(p0 + dp1 + dp2, normal, uv0 + duv1 + duv2)

		util.expect_false(indices.push_back(i + 0))
		util.expect_false(indices.push_back(i + 1))
		util.expect_false(indices.push_back(i + 2))
		util.expect_false(indices.push_back(i + 2))
		util.expect_false(indices.push_back(i + 1))
		util.expect_false(indices.push_back(i + 3))


	func add_tri(
			p0: Vector3,
			p1: Vector3,
			p2: Vector3,
			uv0: Vector2,
			uv1: Vector2,
			uv2: Vector2,
	) -> void:
		var i := size

		var dp1 := p1 - p0
		var dp2 := p2 - p0

		var normal := dp2.cross(dp1)

		_add_point(p0, normal, uv0)
		_add_point(p1, normal, uv1)
		_add_point(p2, normal, uv2)

		util.expect_false(indices.push_back(i + 0))
		util.expect_false(indices.push_back(i + 1))
		util.expect_false(indices.push_back(i + 2))


	func build() -> ArrayMesh:
		var surface := []
		var mesh := ArrayMesh.new()

		var _size := surface.resize(Mesh.ARRAY_MAX)
		surface[Mesh.ARRAY_VERTEX] = verts
		surface[Mesh.ARRAY_NORMAL] = normals
		surface[Mesh.ARRAY_TEX_UV] = uvs
		surface[Mesh.ARRAY_INDEX] = indices

		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface)

		return mesh


class MeshFactory:
	var tileset_grid_size := Vector2.ONE
	var tileset_size: Vector2


	func _uv(tile: Vector2i, u: float, v: float) -> Vector2:
		return (Vector2(tile) + Vector2(u, v)) * tileset_grid_size / tileset_size


	func quad(dx: float, dy: float, dz: float, tile: Vector2i) -> ArrayMesh:
		assert(dx > 0.0)
		assert(dz > 0.0)

		var b := MeshBuilder.new()

		b.add_quad(
			Vector3(0.0, dy, 0.0),
			Vector3(dx, dy, 0.0),
			Vector3(0.0, dy, dz),
			_uv(tile, 0.0, 0.0),
			_uv(tile, 1.0, 0.0),
			_uv(tile, 0.0, 1.0),
		)

		return b.build()


	func box(dx: float, dy: float, dz: float, tile_top: Vector2i, tile_side: Vector2i) -> ArrayMesh:
		assert(dx > 0.0)
		assert(dy > 0.0)
		assert(dz > 0.0)

		var b := MeshBuilder.new()

		# Top
		b.add_quad(
			Vector3(0.0, dy, 0.0),
			Vector3(dx, dy, 0.0),
			Vector3(0.0, dy, dz),
			_uv(tile_top, 0.0, 0.0),
			_uv(tile_top, 1.0, 0.0),
			_uv(tile_top, 0.0, 1.0),
		)

		# Front
		b.add_quad(
			Vector3(0.0, dy, dz),
			Vector3(dx, dy, dz),
			Vector3(0.0, 0.0, dz),
			_uv(tile_side, 0.0, 0.0),
			_uv(tile_side, 1.0, 0.0),
			_uv(tile_side, 0.0, dy),
		)

		# Left
		b.add_quad(
			Vector3(0.0, dy, 0.0),
			Vector3(0.0, dy, dz),
			Vector3(0.0, 0.0, 0.0),
			_uv(tile_side, 0.0, 0.0),
			_uv(tile_side, 1.0, 0.0),
			_uv(tile_side, 0.0, dy),
		)

		# Right
		b.add_quad(
			Vector3(dx, dy, dz),
			Vector3(dx, dy, 0.0),
			Vector3(dx, 0.0, dz),
			_uv(tile_side, 0.0, 0.0),
			_uv(tile_side, 1.0, 0.0),
			_uv(tile_side, 0.0, dy),
		)

		return b.build()


	func ramp(
			dx: float,
			dy: float,
			dz: float,
			tile_top: Vector2i,
			tile_side: Vector2i,
	) -> ArrayMesh:
		assert(dx > 0.0)
		assert(dy > 0.0)
		assert(dz > 0.0)

		var b := MeshBuilder.new()

		var frac := dz / (dy + dz)

		var y1 := dy - dy * frac
		var z1 := dz * frac

		var frac_uv := dy

		# Split ramp in two to repeat UV section
		# Top (upper section)
		b.add_quad(
			Vector3(0.0, dy, 0.0),
			Vector3(dx, dy, 0.0),
			Vector3(0.0, y1, z1),
			_uv(tile_top, 0.0, 0.0),
			_uv(tile_top, 1.0, 0.0),
			_uv(tile_top, 0.0, 1.0),
		)
		# Top (lower section)
		b.add_quad(
			Vector3(0.0, y1, z1),
			Vector3(dx, y1, z1),
			Vector3(0.0, 0.0, dz),
			_uv(tile_top, 0.0, 0.0),
			_uv(tile_top, 1.0, 0.0),
			_uv(tile_top, 0.0, frac_uv),
		)

		# Left
		b.add_tri(
			Vector3(0.0, dy, 0.0),
			Vector3(0.0, 0.0, dz),
			Vector3(0.0, 0.0, 0.0),
			_uv(tile_side, 0.0, 0.0),
			_uv(tile_side, 1.0, 1.0),
			_uv(tile_side, 0.0, dy),
		)

		# Right
		b.add_tri(
			Vector3(dx, 0.0, dz),
			Vector3(dx, dy, 0.0),
			Vector3(dx, 0.0, 0.0),
			_uv(tile_side, 0.0, 1.0),
			_uv(tile_side, 1.0, 0.0),
			_uv(tile_side, 1.0, dy),
		)

		return b.build()


func _add_lib_mesh(
		ml: MeshLibrary,
		position: Vector3,
		mesh: ArrayMesh,
) -> void:
	if material:
		for i in mesh.get_surface_count():
			mesh.surface_set_material(i, material)

	var mi := MeshInstance3D.new()
	mi.position = position
	mi.mesh = mesh
	parent.add_child(mi)
	mi.owner = get_tree().edited_scene_root

	var id := ml.get_last_unused_item_id()
	ml.create_item(id)
	ml.set_item_mesh(id, mesh)

	if collisions:
		mi.create_convex_collision(true, true)
		var coll_shape: CollisionShape3D = mi.get_child(0).get_child(0)
		ml.set_item_shapes(id, [coll_shape.shape])
