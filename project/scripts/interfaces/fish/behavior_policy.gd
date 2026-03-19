## Base class for fish behavior strategies. Subclass this and override the
## virtual methods to define how a specific entity reacts to player proximity.
## Appears as "BehaviorPolicy" in the Add Node dialog.
class_name BehaviorPolicy
extends Node


func on_player_enter_attack_range(_entity: Node3D) -> void:
	push_error(get_script().resource_path + ": on_player_enter_attack_range() not implemented")


func on_player_exit_attack_range(_entity: Node3D) -> void:
	push_error(get_script().resource_path + ": on_player_exit_attack_range() not implemented")


func on_player_enter_perception_range(_entity: Node3D) -> void:
	push_error(get_script().resource_path + ": on_player_enter_perception_range() not implemented")


func on_player_leave_perception_range(_entity: Node3D) -> void:
	push_error(get_script().resource_path + ": on_player_leave_perception_range() not implemented")

func while_player_being_followed(entity: Node3D) -> void:
	var node := entity as CharacterBody3D
	node.nav_agent.target_position = node.target_player.global_position

	var next_pos: Vector3 = node.nav_agent.get_next_path_position()
	var direction: Vector3 = (next_pos - node.global_position).normalized()

	var to_player: Vector3 = (node.target_player.global_position - node.global_position).normalized()
	direction = direction.lerp(to_player, 0.5).normalized()

	node.velocity = direction * node.chase_speed

	if node.velocity.length_squared() > 0.001:
		node.look_at(node.global_position + node.velocity.normalized(), Vector3.UP)

	var _collided := node.move_and_slide()


func while_player_not_being_followed(entity: Node3D) -> void:
	var node := entity as CharacterBody3D
	var next_pos: Vector3 = node.nav_agent.get_next_path_position()
	var direction: Vector3 = (next_pos - node.global_position).normalized()

	node.velocity = direction * node.swim_speed

	if node.velocity.length_squared() > 0.001:
		node.look_at(node.global_position + node.velocity.normalized(), Vector3.UP)

	var _collided := node.move_and_slide()