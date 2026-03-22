class_name PauseMenuSystem
extends Node

# TODO: Move this to separate system
@export var capture_mouse := true
@export var show_on_start := true

@export var menu: Menu
@export var replay_system: ReplaySystem
@export var save_state: SaveState
@export var system_dialog: SystemDialog
@export var dither_filter: CanvasLayer
@export var palette_filter: CanvasLayer

var paused := false
var _at_main_menu := true

# Public Methods


func unpause() -> void:
	if _at_main_menu:
		signalbus.game_started.emit()
	paused = false
	_at_main_menu = false
	menu.hide()
	if capture_mouse:
		util.set_mouse_captured(true)


func pause() -> void:
	paused = true
	menu.show()
	util.set_mouse_captured(false)


func is_menu_open() -> bool:
	return menu.visible

# Interface Methods


func _ready() -> void:
	assert(menu)
	assert(replay_system)
	assert(save_state)
	assert(system_dialog)
	assert(dither_filter)
	assert(palette_filter)

	process_mode = PROCESS_MODE_ALWAYS
	util.aok(get_window().focus_exited.connect(pause))
	call_deferred(&"_build_menu")
	call_deferred(&"_show_startup")


func _physics_process(_delta: float) -> void:
	if paused != get_tree().paused:
		get_tree().paused = paused


func _notification(what: int) -> void:
	match what:
		MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT:
			pause()

# Private Methods


func _save_game_dialog() -> void:
	var filename := await system_dialog.file_save_dialog("*.sav", "Save File")
	if filename:
		util.aok(save_state.save_to_file(filename))


func _load_game_dialog() -> void:
	var filename := await system_dialog.file_open_dialog("*.sav", "Save File")
	if filename:
		var _err := save_state.load_from_file(filename)


func _is_at_main_menu() -> bool:
	return _at_main_menu


func _is_not_at_main_menu() -> bool:
	return not _at_main_menu


func _build_menu() -> void:
	menu.build(
		[
			Menu.button("Start Game", unpause) #
			.visible_when(_is_at_main_menu) #
			.focus(),
			Menu.button("Continue", unpause) #
			.action("ui_cancel") #
			.visible_when(_is_not_at_main_menu) #
			.focus(),
			Menu.button("Save Game", _save_game_dialog) #
			.visible_when(_is_not_at_main_menu) #
			.desktop_only(),
			Menu.button("Load Game", _load_game_dialog) #
			.desktop_only(),
			Menu.button("Load Replay", replay_system._replay_open_dialog) #
			.desktop_only(),
			Menu.checkbox("Palette Filter", palette_filter.set_visible) #
			.toggled(palette_filter.visible),
			Menu.checkbox("Dither Filter", dither_filter.set_visible) #
			.toggled(dither_filter.visible),
			Menu.button("Quit", replay_system._save_replay_and_quit) #
			.desktop_only(),
		],
	)


func _show_startup() -> void:
	if show_on_start:
		menu.show()
	else:
		unpause()
