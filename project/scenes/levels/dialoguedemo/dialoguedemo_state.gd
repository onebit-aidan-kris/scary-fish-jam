extends Node

@export var alice_is_dead := false
@export var is_win := false
@export var is_draw := false
@export var has_played_at_least_once := false
@export var alice_move := ""
@export var player_move := ""
@export var alice_score := 0
@export var player_score := 0

@onready var start_dialogue_button: Button = %StartDialogueButton
@onready var dialogue_entry: DialogueEntry = $DialogueEntry

const valid_moves := ["rock", "paper", "scissors"]


func choose(move: String) -> void:
	assert(move in valid_moves)
	player_move = move
	alice_move = valid_moves.pick_random()

	print("player move: ", player_move, " Alice move: ", alice_move)

	is_draw = player_move == alice_move
	is_win = (
		(player_move == "rock" and alice_move == "scissors") or
		(player_move == "paper" and alice_move == "rock") or
		(player_move == "scissors" and alice_move == "paper")
	)

	if is_win:
		player_score += 1
	elif not is_draw:
		alice_score += 1

	has_played_at_least_once = true


func shot_alice() -> void:
	alice_is_dead = true


func _ready() -> void:
	assert(start_dialogue_button)
	assert(dialogue_entry)

	util.aok(start_dialogue_button.pressed.connect(dialogue_entry.start))
	start_dialogue_button.grab_focus()
