extends Node

##
## Component for entities that can detect the player via a vision cone.
## Emits signals when the player enters/exits detection range.
##
## Assumes:
##   - A VisionCone node exists as a sibling or child (OR set via export)
##   - VisionCone emits `boat_detected(boat: Node3D)` and `boat_lost(boat: Node3D)`
##
## Usage:
##   - Add as child of any CharacterBody3D that needs player detection
##   - Ensure parent node implements `on_player_detected(player: Node3D)` and `on_player_lost(player: Node3D)`
##   - Connect to `player_detected` / `player_lost` signals, OR check `state` to manually detect/lose player
##

@export var vision_cone: Node3D
@export var detection_radius := 15.0
@export var cone_half_angle_deg := 45.0

enum State {NOT_DETECTED, DETECTED}

var state: State = State.NOT_DETECTED
var tracked_player: Node3D = null


func _ready() -> void:
	vision_cone = util.load_export_or_related_node(self , &"VisionCone", vision_cone)
	if vision_cone:
		_connect_vision_cone_signals()
	else:
		call_deferred("_setup_manual_detection")


func _connect_vision_cone_signals() -> void:
	if vision_cone.has_signal("boat_detected"):
		vision_cone.boat_detected.connect(_on_player_detected)
		vision_cone.boat_lost.connect(_on_player_lost)
	elif vision_cone.has_signal("player_spotted"):
		vision_cone.player_spotted.connect(_on_player_detected)
		vision_cone.player_lost.connect(_on_player_lost)


func _setup_manual_detection() -> void:
	set_physics_process(true)


func _physics_process(_delta: float) -> void:
	pass


func _on_player_detected(player: Node3D) -> void:
	if state == State.DETECTED:
		return
	state = State.DETECTED
	tracked_player = player
	#player_detected.emit(player)
	var parent := get_parent()
	if parent.has_method("on_player_detected"):
		parent.on_player_detected(player)


func _on_player_lost(player: Node3D) -> void:
	if state == State.NOT_DETECTED:
		return
	state = State.NOT_DETECTED
	tracked_player = null
	#player_lost.emit(player)
	var parent := get_parent()
	if parent.has_method("on_player_lost"):
		parent.on_player_lost(player)


func is_player_detected() -> bool:
	return state == State.DETECTED
