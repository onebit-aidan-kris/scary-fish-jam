@tool
extends Node3D

const rock_scene := preload("uid://cqgo7x3ibdciy")

@export_range(10.0, 200.0, 1.0, "exp") var radius := 100.0:
	set(value):
		radius = max(value, 1.0)
		regenerate()
@export_range(0.0, 100.0, 0.1, "exp") var thickness := 3.0:
	set(value):
		thickness = max(value, 0.0)
		regenerate()
@export_range(1.0, 20.0, 0.1, "exp") var density := 1.0:
	set(value):
		density = max(value, 0.0)
		regenerate()


func regenerate() -> void:
	for child in get_children():
		child.queue_free()
	
	var count := int(radius * density)
	for i in count:
		var a := 2.0 * PI * i / count
		var r := randfn(radius, thickness)
		
		var rock: Node3D = rock_scene.instantiate()
		rock.position = Vector3.FORWARD.rotated(Vector3.UP, a) * r
		add_child(rock)
	
