class_name ReplaySystem
extends Node

@export var pause_menu_system: PauseMenuSystem
@export var player_input: PlayerInput
@export var save_state: SaveState
@export var system_dialog: SystemDialog

@onready var replay: Replay = $Replay


func run_from_file(filename: String) -> void:
	if OK == replay.load_from_file(filename):
		replay.start()


func _ready() -> void:
	assert(pause_menu_system)
	assert(player_input)
	assert(save_state)
	assert(system_dialog)
	assert(replay)

	util.aok(replay.load_frame.connect(_replay_load_frame))
	util.aok(replay.request_frame.connect(_replay_save_frame))


func _replay_load_frame(frame: Dictionary) -> void:
	var res := gdserde.deserialize_object(player_input, frame)
	assert(not res.err, res.err)
	if not replay.is_active:
		print("REPLAY DONE")
		pause_menu_system.pause()


func _replay_save_frame() -> void:
	replay.add_frame(gdserde.serialize_object(player_input))


func _save_replay_and_quit() -> void:
	if replay.enabled:
		util.aok(replay.save_to_file("replay.dat"))

	await get_tree().process_frame
	get_tree().quit()


func _restart_replay() -> void:
	save_state.reset()
	replay.restart()


func _replay_open_dialog() -> void:
	var filename := await system_dialog.file_open_dialog("*.dat", "Replay File")
	if filename:
		var _err := replay.load_from_file(filename)
		_restart_replay()
		pause_menu_system.unpause()
