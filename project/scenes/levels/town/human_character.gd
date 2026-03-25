@tool
class_name HumanCharacter
extends CharacterBody2D

@warning_ignore("unused_signal")
signal interacted

enum Direction {
	NORTH,
	SOUTH,
	EAST,
	WEST,
}

@export var player_controlled := false
@export var sprite_frames: SpriteFrames:
	set = set_sprite_frames
@export var direction: Direction = Direction.SOUTH:
	set = set_direction
@export var animating := false:
	set = set_animating
@export_range(0.1, 2.0, 0.1) var animating_speed_scale := 1.0:
	set = set_animating_speed_scale
@export var walk_speed := 100.0

@onready var _human_sprite: HumanSprite2D = $HumanSprite2D

@onready var _interact_north: RayCast2D = $InteractNorth
@onready var _interact_south: RayCast2D = $InteractSouth
@onready var _interact_east: RayCast2D = $InteractEast
@onready var _interact_west: RayCast2D = $InteractWest

var activated_path

func _ready() -> void:
	assert(_human_sprite)

	assert(_interact_north)
	assert(_interact_south)
	assert(_interact_east)
	assert(_interact_west)

	set_sprite_frames(sprite_frames)
	set_direction(direction)
	set_animating(animating)
	set_animating_speed_scale(animating_speed_scale)


func _physics_process(_delta: float) -> void:
	# Don't move character in editor
	if Engine.is_editor_hint():
		return

	if activated_path:
		print("following path: ", activated_path)
		_follow_path(activated_path)

	if player_controlled:
		if gamestate.player_input.interact:
			_player_interact()
		_player_move(gamestate.player_input.move)


func _player_interact() -> void:
	var raycast: RayCast2D
	match direction:
		Direction.NORTH:
			raycast = _interact_north
		Direction.SOUTH:
			raycast = _interact_south
		Direction.EAST:
			raycast = _interact_east
		Direction.WEST:
			raycast = _interact_west
		_:
			assert(false)
			return

	if raycast.is_colliding():
		Interactable.interact(raycast.get_collider())


func _player_move(move: Vector2) -> void:
	velocity = move * walk_speed

	if velocity.is_zero_approx():
		set_animating(false)
	else:
		set_direction_vector(velocity)
		set_animating(true)

	var _collided := move_and_slide()


func set_sprite_frames(value: SpriteFrames) -> void:
	sprite_frames = value
	if _human_sprite and sprite_frames:
		_human_sprite.sprite_frames = sprite_frames


func set_direction(value: Direction) -> void:
	direction = value

	if _human_sprite:
		var anim: StringName
		match direction:
			Direction.NORTH:
				anim = &"walk-n"
			Direction.SOUTH:
				anim = &"walk-s"
			Direction.EAST:
				anim = &"walk-e"
			Direction.WEST:
				anim = &"walk-w"
			_:
				assert(false)
				return
		_human_sprite.animation = anim


func set_animating(value: bool) -> void:
	var changed := value != animating
	animating = value
	if _human_sprite:
		if animating:
			if changed:
				_human_sprite.frame = 1
				_human_sprite.frame_progress = 0.0
			_human_sprite.play()
		else:
			_human_sprite.pause()
			_human_sprite.frame = 0
			_human_sprite.frame_progress = 0.0


func set_animating_speed_scale(value: float) -> void:
	animating_speed_scale = value
	if _human_sprite:
		_human_sprite.speed_scale = animating_speed_scale


func set_direction_vector(vector: Vector2) -> void:
	var abs_x := absf(vector.x)
	var abs_y := absf(vector.y)
	var is_diagonal := is_equal_approx(abs_x, abs_y)
	var is_x_bigger := abs_x > abs_y
	var is_wrong_dir := (
		(vector.x > 0 and direction == Direction.WEST) or
		(vector.x < 0 and direction == Direction.EAST) or
		(vector.y > 0 and direction == Direction.NORTH) or
		(vector.y < 0 and direction == Direction.SOUTH)
	)
	if is_wrong_dir or not is_diagonal:
		if is_x_bigger:
			if vector.x > 0:
				set_direction(Direction.EAST)
			elif vector.x < 0:
				set_direction(Direction.WEST)
		else:
			if vector.y > 0:
				set_direction(Direction.SOUTH)
			elif vector.y < 0:
				set_direction(Direction.NORTH)

func _follow_path(ap) -> void:
	if ap.is_finished():
		ap.deactivate()
		return

	var target: Vector2 = ap.get_next_position()
	var diff := target - global_position

	if diff.length() < 4.0:
		ap.advance()
		return

	_player_move(diff.normalized())
