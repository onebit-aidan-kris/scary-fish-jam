class_name FishEntity
extends CharacterBody3D

enum State {PATROLLING, FOLLOWING}

@export var path_node: Node3D
@export var swim_speed := 3.0
@export var chase_speed := 5.0
@export var attackable: Node = null
@export var player_detectable: Node = null
@export var behavior_policy: Node = null # AttackPolicy subclass


@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var patrol_behavior: Node = $PatrolBehavior


var child_mesh: MeshInstance3D
var highlight_circle: MeshInstance3D
var state := State.PATROLLING
var target_player: Node3D = null


func _ready() -> void:
	child_mesh = get_node("MeshInstance3D")
	print("patrol path is: ", path_node)
	patrol_behavior.nav_agent = nav_agent
	patrol_behavior.set_patrol_nodes(path_node)

	attackable = util.load_export_or_related_node(self , &"Attackable", attackable, false) as Node
	player_detectable = util.load_export_or_related_node(self , &"PlayerDetectable", player_detectable, false) as Node

	#Default to the BehaviorPolicy node at the root if none is attached as a child to this node.
	behavior_policy = util.load_export_or_absolute_node(self , &"BehaviorPolicy", behavior_policy) as BehaviorPolicy
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


func _process(_delta: float) -> void:
	# If the sonar is active, highlight the fish in the lake
	if highlight_circle and (highlight_circle.mesh as SphereMesh).radius > 0:
		(highlight_circle.mesh as SphereMesh).radius -= 0.003
	elif highlight_circle:
		highlight_circle.queue_free()
		highlight_circle = null

func on_player_detected(player: Node3D) -> void:
	print("player detected!!")
	state = State.FOLLOWING
	target_player = player


func on_player_lost(_player: Node3D) -> void:
	state = State.PATROLLING
	target_player = null

func highlight() -> void:
	if highlight_circle:
		return
	var water_surface: MeshInstance3D = get_tree().get_first_node_in_group("WaterSurface")
	var water_surface_pos: Vector3 = water_surface.global_position
	var fish_pos: Vector3 = global_position
	var layer_offset := 1.0
	var intersection_y: float = fish_pos.y + water_surface_pos.y + layer_offset

	highlight_circle = MeshInstance3D.new()
	var sphere_mesh := SphereMesh.new()
	sphere_mesh.radius = 3
	sphere_mesh.height = 3
	highlight_circle.mesh = sphere_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.RED
	mat.emission_energy_multiplier = 5.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	highlight_circle.set_surface_override_material(0, mat)

	get_tree().root.add_child(highlight_circle)
	highlight_circle.global_position = Vector3(fish_pos.x, intersection_y, fish_pos.z)


func play_animation(animation: String) -> void:
	pass # TODO: Implement this.
