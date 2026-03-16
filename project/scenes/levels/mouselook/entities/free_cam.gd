class_name FreeCam
extends Camera3D

const gdserde_class := &"FreeCam"
const gdserde_props := [&"transform"]

@export var take_control_on_ready := false

@export var maybe_input: PlayerInput

@export var base_speed := 5.0
@export var sprint_speed := 20.0

var look_origin := Vector2.ZERO


func give_control(player_input: PlayerInput) -> void:
	look_origin = Vector2(rotation_degrees.x, rotation_degrees.y) - player_input.look
	maybe_input = player_input


func _ready() -> void:
	if take_control_on_ready:
		give_control(gamestate.player_input)


func _physics_process(delta: float) -> void:
	if maybe_input:
		var updown := 0.0
		if maybe_input.jump:
			updown += 1.0
		if maybe_input.crouch:
			updown -= 1.0

		var speed := base_speed * delta
		if maybe_input.sprint:
			speed = sprint_speed * delta

		var direction := (
			transform.basis * Vector3(maybe_input.move.x, 0, maybe_input.move.y)
			+ Vector3(0, updown, 0)
		).normalized()

		position += direction * speed


func _process(_delta: float) -> void:
	if maybe_input:
		rotation_degrees.x = maybe_input.look.x + look_origin.x
		rotation_degrees.y = maybe_input.look.y + look_origin.y
