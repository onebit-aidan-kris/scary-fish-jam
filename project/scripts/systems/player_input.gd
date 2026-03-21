class_name PlayerInput
extends Node

const gdserde_class := &"PlayerInput"
const gdserde_props := [
	&"look",
	&"move",
	&"sprint",
	&"crouch",
	&"jump",
	&"interact",
]

@export var replay_system: ReplaySystem
@export var pause_menu_system: PauseMenuSystem

# TODO: Make parameter
const sensitivity := 0.2
const min_angle := -90.0
const max_angle := 90

var look := Vector2.ZERO
var move := Vector2.ZERO
var interact := false
var sprint := false
var crouch := false
var jump := false


func _is_listening() -> bool:
	var replay_is_inactive := replay_system == null or not replay_system.replay.is_active
	var menu_is_closed := pause_menu_system == null or not pause_menu_system.is_menu_open()

	return replay_is_inactive and menu_is_closed


func _ready() -> void:
	# Missing system asserts for debugging, but not actually required for logic
	assert(replay_system)
	assert(pause_menu_system)


func _physics_process(_delta: float) -> void:
	if _is_listening():
		move = Input.get_vector(
			"move_left",
			"move_right",
			"move_forward",
			"move_backward",
		)
		sprint = Input.is_action_pressed("sprint")
		crouch = Input.is_action_pressed("crouch")
		jump = Input.is_action_pressed("jump")
		interact = Input.is_action_just_pressed("interact")


func _input(event: InputEvent) -> void:
	if _is_listening():
		if event is InputEventMouseMotion:
			var ev: InputEventMouseMotion = event
			look.y -= (ev.relative.x * sensitivity)
			look.x -= (ev.relative.y * sensitivity)
			look.x = clamp(look.x, min_angle, max_angle)
