class_name WinCondition
extends Node

var _won := false


func _ready() -> void:
	util.aok(signalbus.fish_caught.connect(_on_fish_caught))


func _on_fish_caught(fish: Node3D) -> void:
	if _won:
		return

	for child in get_children():
		if child is FishCountCondition:
			child.on_fish_caught(fish)

	_check_all_satisfied()


func _check_all_satisfied() -> void:
	var has_any_condition := false
	for child in get_children():
		if child is FishCountCondition:
			has_any_condition = true
			if not child.is_satisfied():
				return

	if has_any_condition:
		_won = true
		print("All win conditions met!")
		signalbus.level_won.emit()
