extends Node

@export var path_start : Vector2i
@export var path_end : Vector2i

var astar_grid : AStarGrid2D
var path
var path_index := 0

var _full_path_name : String

var activated := true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert(path_start)
	assert(path_end)
	astar_grid = AStarGrid2D.new()
	astar_grid.cell_size = Vector2(16, 16)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	path = astar_grid.get_point_path(path_start, path_end)
	astar_grid.update()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if activated and astar_grid:
		astar_grid.update()

func activate() -> void:
	activated = true

func get_next_position() -> Vector2i:
	return path[path_index]

func update_path_position() -> Vector2i:
	path_index += 1
	if path_index >= path.size():
		path_index = 0
	return path[path_index]