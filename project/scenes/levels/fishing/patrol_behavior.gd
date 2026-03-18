class_name PatrolBehavior
extends Node

var nav_agent: NavigationAgent3D
var points: Array[Node3D] = []
var curr_points_idx := 0


func set_patrol_nodes(patrol_path_root: Node) -> void:
	for child: Node in patrol_path_root.get_children():
		if child is Node3D:
			points.append(child)
	_set_next_target()


func _physics_process(_delta: float) -> void:
	assert(nav_agent, "parent must set nav_agent in _ready()")
	if nav_agent.is_navigation_finished():
		_set_next_target()


func _set_next_target() -> void:
	if points.size() > 0:
		nav_agent.target_position = points[curr_points_idx].global_position
		curr_points_idx = (curr_points_idx + 1) % points.size()
