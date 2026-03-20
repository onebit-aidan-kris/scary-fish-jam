class_name FishEntity
extends CharacterBody3D

enum State {PATROLLING, FOLLOWING}

@export var path_node: Node3D
@export var swim_speed := 3.0
@export var chase_speed := 5.0
@export var attackable: Node = null
@export var player_detectable: Node = null
@export var behavior_policy: BehaviorPolicy = null # AttackPolicy subclass


@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var patrol_behavior: PatrolBehavior = $PatrolBehavior


var child_mesh: MeshInstance3D
var state := State.PATROLLING
var target_player: Node3D = null


func _ready() -> void:
	child_mesh = get_node("MeshInstance3D")
	print("patrol path is: ", path_node)
	patrol_behavior.nav_agent = nav_agent
	patrol_behavior.set_patrol_nodes(path_node)

	attackable = util.load_export_or_related_node(self , &"Attackable", attackable, false)
	player_detectable = util.load_export_or_related_node(self , &"PlayerDetectable", player_detectable, false)

	#Default to the BehaviorPolicy node at the root if none is attached as a child to this node.
	behavior_policy = util.load_export_or_absolute_node(self , &"BehaviorPolicy", behavior_policy)
	print("behavior policy is: ", behavior_policy)
	if not behavior_policy:
		return
	

func _physics_process(_delta: float) -> void:
	if not behavior_policy:
		return

	if state == State.FOLLOWING and target_player:
		behavior_policy.while_player_being_followed(self )
	else:
		behavior_policy.while_player_not_being_followed(self )



func on_player_detected(player: Node3D) -> void:
	print("player detected!!")
	state = State.FOLLOWING
	target_player = player


func on_player_lost(_player: Node3D) -> void:
	state = State.PATROLLING
	target_player = null

func highlight() -> void:
	signalbus.sonar_highlight.emit(global_position)


func play_animation(animation: String) -> void:
	pass # TODO: Implement this.
