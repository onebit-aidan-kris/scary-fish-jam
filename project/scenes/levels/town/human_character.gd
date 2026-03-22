@tool
class_name HumanCharacter
extends CharacterBody2D

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

@onready var human_sprite: HumanSprite2D = $HumanSprite2D


func set_sprite_frames(value: SpriteFrames) -> void:
	sprite_frames = value
	if human_sprite and sprite_frames:
		human_sprite.sprite_frames = sprite_frames


func set_direction(value: Direction) -> void:
	direction = value
	if human_sprite:
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
		human_sprite.animation = anim


func set_animating(value: bool) -> void:
	var changed := value != animating
	animating = value
	if human_sprite:
		if animating:
			if changed:
				human_sprite.frame = 1
				human_sprite.frame_progress = 0.0
			human_sprite.play()
		else:
			human_sprite.pause()
			human_sprite.frame = 0
			human_sprite.frame_progress = 0.0


func set_animating_speed_scale(value: float) -> void:
	animating_speed_scale = value
	if human_sprite:
		human_sprite.speed_scale = animating_speed_scale


func set_direction_vector(vector: Vector2) -> void:
	var is_diagonal := is_equal_approx(absf(vector.x), absf(vector.y))
	var is_wrong_dir := (
		(vector.x > 0 and direction == Direction.WEST) or
		(vector.x < 0 and direction == Direction.EAST) or
		(vector.y > 0 and direction == Direction.NORTH) or
		(vector.y < 0 and direction == Direction.SOUTH)
	)
	if is_wrong_dir or not is_diagonal:
		if vector.x > 0:
			set_direction(Direction.EAST)
		elif vector.x < 0:
			set_direction(Direction.WEST)
		elif vector.y > 0:
			set_direction(Direction.SOUTH)
		elif vector.y < 0:
			set_direction(Direction.NORTH)


func _ready() -> void:
	assert(human_sprite)
	set_sprite_frames(sprite_frames)
	set_direction(direction)
	set_animating(animating)
	set_animating_speed_scale(animating_speed_scale)


func _physics_process(_delta: float) -> void:
	# Don't move character in editor
	if not Engine.is_editor_hint():
		if player_controlled:
			velocity = gamestate.player_input.move * walk_speed

			if velocity.is_zero_approx():
				set_animating(false)
			else:
				set_direction_vector(velocity)
				set_animating(true)

			var _collided := move_and_slide()
