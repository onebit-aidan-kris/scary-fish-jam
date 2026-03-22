extends MeshInstance3D

class_name NetArc

static var h: float = 3.0
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

	# Vertical parabolic arc: rises from boat, peaks at midpoint, lands at net_position
	# P(t) = lerp(P0, P1, t) + UP * 4h*t*(1-t)
	for i: int in parabola_segments:
		var t: float = float(i) / (parabola_segments - 1)
		var linear: Vector3 = boat_position.lerp(net_position, t)
		var arc_height: float = 4.0 * h * t * (1.0 - t)
		vertices.append(Vector3(linear.x, boat_position.y + arc_height, linear.z))

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices

	var arr_mesh := ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINE_STRIP, arrays)
	return arr_mesh
