extends Node3D

###
# Component node for attacking-related behaviors for entities capable of attacking the player.
# Responsible for:
#  - Containing hitbox and detecting player collision with attack hitbox
#  - Invoking attack animations on parent character when attack is initiated
#  - Controlling attack cooldown
# 
#  Note:  Movement in the attacking phase is NOT handled by this component.
#
# Assumes:
#  - Presence of Hitbox, passed in as export variable or sibling of parent node.
#

signal player_damaged(damage_amount: int) # Sends signal to boat to receive damage.
enum State {NOT_ATTACKING, ATTACKING}

# Will search for adjacent hitbox if none specified.
@export var hitbox: Area3D

var state := State.NOT_ATTACKING
var target_boat: Node3D = null
var playing_attack_animation := false
var attack_cooldown := 0.0
var entity_being_attacked: Node3D = null


func _ready() -> void:
	# Load hitbox
	hitbox = util.load_export_or_related_node(self , &"Hitbox", hitbox) as Area3D
	if hitbox:
		var _err1 := hitbox.body_entered.connect(_on_hitbox_body_entered)
		var _err2 := hitbox.body_exited.connect(_on_hitbox_body_exited)


func _physics_process(_delta: float) -> void:
	if state != State.ATTACKING:
		return	

	attack_policy(_delta)

func _on_hitbox_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		start_attacking(body)


func _on_hitbox_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_on_player_exited(body)
		stop_attacking()


func start_attacking(body: Node3D) -> void:
	print("Attacking!!!")
	entity_being_attacked = body
	state = State.ATTACKING


func _on_player_entered(_player: Node3D) -> void:
	start_attacking(_player)


func _on_player_exited(_player: Node3D) -> void:
	#Parent responsible for stopping attack.
	pass


func stop_attacking() -> void:
	state = State.NOT_ATTACKING
	# Ensure if there's an in flight attack animation, it is stopped.
	# Ensure if there's an attack cooldown, it is reset.
	playing_attack_animation = false
	attack_cooldown = 0.0


# Can subclass this component and override this method to change _how_ attacks are done.
func attack_policy(_delta: float) -> void:
	# If state switches to attacking, play attack animation and start cooldown
	if state == State.ATTACKING and not playing_attack_animation:
		print("Firing attack animation!!!")
		playing_attack_animation = true
		get_parent().play_animation(&"Attack")
		entity_being_attacked.receive_damage(10)
		attack_cooldown = 0.5

		# Standard attack policy demands the fish return when done attacking.
		# This can be changed via subclassing this component and overriding the disengage_from_player method.
		get_parent().disengage_from_player()


	# If cooldown is active, decrement it.
	if attack_cooldown > 0.0:
		attack_cooldown -= _delta
		if attack_cooldown <= 0.0:
			playing_attack_animation = false
