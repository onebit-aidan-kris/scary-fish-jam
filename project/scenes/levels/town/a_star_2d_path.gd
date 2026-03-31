class_name AStar2DPath
extends Node

@export var path_start: Vector2i
@export var path_end: Vector2i
@export var grid_region: Rect2i = Rect2i(0, 0, 50, 50)
@export var collision_layers: Array[TileMapLayer] = []

var astar_grid: AStarGrid2D
var path: PackedVector2Array
var path_index := 0

var activated := true


func _ready() -> void:
	assert(path_start)
	assert(path_end)
	astar_grid = AStarGrid2D.new()
	astar_grid.region = grid_region
	astar_grid.cell_size = Vector2(16, 16)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	util.mark_solid_from_tilemaps(astar_grid, collision_layers)
	path = astar_grid.get_point_path(path_start, path_end)


func activate() -> void:
	activated = true
	var parent_node = get_parent()
	if parent_node is HumanCharacter:
		parent_node.activated_path = self


func deactivate() -> void:
	activated = false
	var parent_node = get_parent()
	if parent_node is HumanCharacter:
		parent_node.activated_path = null


func get_next_position() -> Vector2:
	return path[path_index]


func is_finished() -> bool:
	return path_index >= path.size()


func advance() -> void:
	path_index += 1
