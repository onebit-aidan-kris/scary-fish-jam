@tool
class_name FishingNetSprite
extends MeshInstance3D

@export var duration_s := 4.0
@export_range(-180, 180, 0.001, "radians_as_degrees") var angular_deviation := deg_to_rad(15)
@export var scale_curve: Curve

@export_category("Editor")
@export var _preview := false


var _initial_transform := Transform3D.IDENTITY


var _is_playing := false
var _time := 0.0
var _angluar_velocity := 0.0


func _ready() -> void:
	_initial_transform = transform
	if not Engine.is_editor_hint() or _preview:
		_start_animation()


func _physics_process(_delta: float) -> void:
	if not _is_playing:
		if Engine.is_editor_hint() and _preview:
			_start_animation()
		else:
			return
	
	_time += _delta
	
	rotate(Vector3.FORWARD, _angluar_velocity * _delta)
	
	var frac := _time / duration_s
	scale = Vector3.ONE * scale_curve.sample(frac)
	if frac > 1.0:
		_is_playing = false
	
	show()


func _start_animation() -> void:
	hide()
	
	transform = _initial_transform

	rotate(transform.basis.z.normalized(), randf_range(0.0, 2.0 * PI))
	_is_playing = true
	_time = 0.0
	_angluar_velocity = randfn(0.0, angular_deviation)
