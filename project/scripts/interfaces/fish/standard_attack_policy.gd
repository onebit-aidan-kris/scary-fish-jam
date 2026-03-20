## Aggressive behavior policy that follows the player, attacks once, then
## returns to patrol. Uses the fish's Attackable component for damage.
class_name StandardAttackPolicy
extends BehaviorPolicy

var _connected_entity: Node3D = null


func on_player_enter_attack_range(entity: Node3D) -> void:
	var attackable := entity.get_node_or_null("Attackable")
	if attackable:
		if not attackable.attack_landed.is_connected(_on_attack_landed):
			_connected_entity = entity
			var _err: int = attackable.attack_landed.connect(_on_attack_landed)
		attackable.start_attacking(entity)


func on_player_exit_attack_range(entity: Node3D) -> void:
	var attackable := entity.get_node_or_null("Attackable")
	if attackable:
		attackable.stop_attacking()


func on_player_enter_perception_range(entity: Node3D) -> void:
	if entity.has_method("on_player_detected"):
		var boat: Node3D = entity.get_tree().get_first_node_in_group("player")
		if boat:
			entity.on_player_detected(boat)


func on_player_leave_perception_range(entity: Node3D) -> void:
	if entity.has_method("on_player_lost"):
		var boat: Node3D = entity.get_tree().get_first_node_in_group("player")
		if boat:
			entity.on_player_lost(boat)


func _on_attack_landed() -> void:
	if not _connected_entity:
		return
	var attackable := _connected_entity.get_node_or_null("Attackable")
	if attackable:
		attackable.stop_attacking()
	if _connected_entity.has_method("on_player_lost"):
		_connected_entity.on_player_lost(_connected_entity)
	_connected_entity = null
