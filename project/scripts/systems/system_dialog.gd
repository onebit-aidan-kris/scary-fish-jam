class_name SystemDialog
extends Node

signal completed(string: String)


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS


func _on_completed(filename: String = "") -> void:
	completed.emit(filename)


func file_dialog(
		file_mode: FileDialog.FileMode,
		filter: String = "",
		description: String = "",
) -> String:
	var fd := FileDialog.new()
	add_child(fd)

	fd.file_mode = file_mode
	fd.use_native_dialog = true
	if filter:
		fd.add_filter(filter, description)
	fd.popup_centered()

	util.aok(fd.file_selected.connect(_on_completed))
	util.aok(fd.canceled.connect(_on_completed))

	var filename: String = await completed

	fd.queue_free()
	return filename


func file_open_dialog(filter: String = "", description: String = "") -> String:
	return await file_dialog(FileDialog.FileMode.FILE_MODE_OPEN_FILE, filter, description)


func file_save_dialog(filter: String = "", description: String = "") -> String:
	return await file_dialog(FileDialog.FileMode.FILE_MODE_SAVE_FILE, filter, description)
