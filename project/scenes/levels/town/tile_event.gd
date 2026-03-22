class_name TileEvent
extends Area2D

signal triggered

@export var portal: TileEvent

const PORTAL_DIST_THRESHOLD := 12.0

var active_body: PhysicsBody2D
var active_body_entry_offset: Vector2


func _ready() -> void:
	assert(portal != self)

	util.aok(body_entered.connect(_on_body_entered))
	util.aok(body_exited.connect(_on_body_exited))


func _on_body_entered(body: PhysicsBody2D) -> void:
	assert(body)
	if active_body:
		return
	print("enter ", name)
	active_body = body
	active_body_entry_offset = body.position - position


func _on_body_exited(body: PhysicsBody2D) -> void:
	assert(body)
	if body != active_body:
		return
	print("exit ", name)

	if portal:
		var exit_offset := body.position - position
		if exit_offset.distance_to(active_body_entry_offset) > PORTAL_DIST_THRESHOLD:
			body.position = portal.position + exit_offset
		triggered.emit()

	active_body = null
