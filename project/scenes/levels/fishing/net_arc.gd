extends MeshInstance3D

class_name NetArc


static var h: float = 10.0 # parabola height
static var parabola_segments: int = 30
#
#
# goal: Given a starting, ending point, and and apex height:
#
# 1) Derive line between starting and ending point
# 2) Given the apex height, draw curve (parabola) that intersects the height points at the starting and ending points
# 3) Apply a quadratic offset to the line to create the net curve.
#
#

func calculate_net_path(boat_position: Vector3, net_position: Vector3) -> ArrayMesh:
	var vertices := PackedVector3Array()

	# Arc direction: perpendicular to the line between endpoints, within the XZ plane
	var forward: Vector3 = (net_position - boat_position)
	forward.y = 0.0
	var perp: Vector3 = Vector3.UP.cross(forward).normalized()

	# P(t) = lerp(P0, P1, t) + perp * 4h*t*(1-t)
	for i: int in parabola_segments:
		var t: float = float(i) / (parabola_segments - 1)
		var linear: Vector3 = boat_position.lerp(net_position, t)
		var arc_offset: Vector3 = perp * (4.0 * h * t * (1.0 - t))
		linear.y = boat_position.y
		vertices.append(linear + arc_offset)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices

	var arr_mesh := ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINE_STRIP, arrays)
	return arr_mesh
