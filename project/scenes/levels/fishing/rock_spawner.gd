@tool
extends Node3D

#const rock_scene := preload("uid://cqgo7x3ibdciy")

@export_range(10.0, 200.0, 1.0, "exp") var radius := 100.0:
	set(value):
		radius = max(value, 1.0)
		regenerate()
@export_range(0.0, 100.0, 0.1, "exp") var thickness := 3.0:
	set(value):
		thickness = max(value, 0.0)
		regenerate()
@export_range(1.0, 1000.0, 0.1, "exp") var density := 1.0:
	set(value):
		density = max(value, 0.0)
		regenerate()
@export_range(1.0, 20.0, 0.1) var mesh_scale := 8.0:
	set(value):
		mesh_scale = value
		regenerate()

@export var material_template: StandardMaterial3D
@export var textures: Array[Texture2D]


func _ready() -> void:
	regenerate()


func regenerate() -> void:
	for child in get_children():
		child.queue_free()

	var count := int(radius * density / textures.size())

	for tex in textures:
		var mat: StandardMaterial3D = material_template.duplicate_deep()
		mat.albedo_texture = tex

		var mesh := QuadMesh.new()
		mesh.size = Vector2(mesh_scale, mesh_scale)
		mesh.material = mat

		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.instance_count = count
		multimesh.mesh = mesh

		for i in count:
			var slice := 2.0 * PI / count
			var a := randfn(slice * i, slice)
			var r := randfn(radius, thickness)
			var pos := Vector3.FORWARD.rotated(Vector3.UP, a) * r
			multimesh.set_instance_transform(i, util.transform_3d(pos))

		var mmi := MultiMeshInstance3D.new()
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.multimesh = multimesh
		add_child(mmi)

	#func regenerate() -> void:
	#var count := int(radius * density)
	#
	#multimesh.instance_count = count
	#
	#for i in count:
	#var a := 2.0 * PI * i / count
	#var r := randfn(radius, thickness)
	#var pos := Vector3.FORWARD.rotated(Vector3.UP, a) * r
	#multimesh.set_instance_transform(i, util.create_transform_3d(pos))

	#func regenerate() -> void:
	#for child in get_children():
	#child.queue_free()
	#
	#var count := int(radius * density)
	#for i in count:
	#var a := 2.0 * PI * i / count
	#var r := randfn(radius, thickness)
	#
	#var rock: Node3D = rock_scene.instantiate()
	#rock.position = Vector3.FORWARD.rotated(Vector3.UP, a) * r
	#add_child(rock)
