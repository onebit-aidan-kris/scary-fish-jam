extends RefCounted

var active: bool = true
var astar_grid: AStarGrid2D
var path: Array[Vector2i] = []
var start_position: Vector2i
var end_position: Vector2i

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if active:
		assert(start_position)
		assert(end_position)
		if not astar_grid:
			astar_grid = AStarGrid2D.new()
			astar_grid.cell_size = Vector2(16, 16)
			astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
			path = astar_grid.get_point_path(Vector2i(21, 27), Vector2i(21, 32))
		astar_grid.update()


func activate() -> void:
	active = true

func set_start_position(position: Vector2i) -> void:
	start_position = position

func set_end_position(position: Vector2i) -> void:
	end_position = position
