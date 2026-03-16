class_name SaveState
extends Node

signal savedata_saving
signal savedata_loaded

## Dictionary[StringName, Dictionary]
var _savedata_state := { }
## Dictionary[StringName, Object]
var _savedata_refs := { }

## Player quick save
var _quick_save: PackedByteArray
## Save of initial game state
var _quick_save_zero: PackedByteArray

# Public Methods


func save_object_state(key: StringName, obj: Object) -> void:
	_savedata_state[key] = gdserde.serialize_object(obj)


func load_object_state(key: StringName, obj: Object) -> void:
	if _savedata_state.has(key):
		var dict: Dictionary = _savedata_state[key]
		var res := gdserde.deserialize_object(obj, dict)
		assert(not res.err, res.err)


func sync_object_state(key: StringName, obj: Object) -> void:
	util.printdbg("Sync state: ", key)

	load_object_state(key, obj)
	if OS.is_debug_build():
		# Debug-only check for serde errors
		var dict := gdserde.serialize_object(obj)
		var res := gdserde.deserialize_object(obj, dict)
		assert(not res.err, res.err)

	_savedata_refs[key] = obj


func quicksave() -> void:
	_quick_save = _serialize_savedata()


func quickload() -> void:
	util.aok(_deserialize_savedata(_quick_save))


func reset() -> void:
	util.aok(_deserialize_savedata(_quick_save_zero))


func save_to_file(filename: String) -> Error:
	var err := OK
	print("Saving game to: ", filename)
	var f := FileAccess.open(filename, FileAccess.ModeFlags.WRITE)
	if not f:
		err = FileAccess.get_open_error()
		printerr(error_string(err))
	elif not f.store_buffer(_serialize_savedata()):
		printerr("Failed to store buffer")
		err = FAILED
	return err


func load_from_file(filename: String) -> Error:
	var err := OK
	print("Loading game from: ", filename)
	var game_data := FileAccess.get_file_as_bytes(filename)
	if not game_data:
		err = FileAccess.get_open_error()
		if err == OK:
			printerr("Empty game save file")
			err = ERR_INVALID_DATA

	if not err:
		err = _deserialize_savedata(game_data)

	if err:
		printerr("Error loading game save '", filename, "': ", error_string(err))

	return err

# Interface Methods


func _ready() -> void:
	call_deferred(&"_root_ready")

# Private Methods


func _root_ready() -> void:
	_quick_save_zero = _serialize_savedata()
	_quick_save = _quick_save_zero


func _deserialize_savedata(packed_data: PackedByteArray) -> Error:
	var unpacked_state: Variant = bytes_to_var(packed_data)
	if unpacked_state is not Dictionary:
		printerr("Save data is not a Dictionary")
		return ERR_INVALID_DATA

	_savedata_state = unpacked_state

	for k: StringName in _savedata_refs:
		if is_instance_valid(_savedata_refs[k]):
			var obj: Object = _savedata_refs[k]
			load_object_state(k, obj)
		else:
			util.expect_true(_savedata_refs.erase(k))

	if OS.is_debug_build():
		util.printdbg("Loaded savedata: ", JSON.stringify(_savedata_state))
	savedata_loaded.emit()
	return OK


func _serialize_savedata() -> PackedByteArray:
	savedata_saving.emit()

	for k: StringName in _savedata_refs:
		if is_instance_valid(_savedata_refs[k]):
			var obj: Object = _savedata_refs[k]
			save_object_state(k, obj)
		else:
			util.expect_true(_savedata_refs.erase(k))

	if OS.is_debug_build():
		util.printdbg("Saved savedata: ", JSON.stringify(_savedata_state))
	return var_to_bytes(_savedata_state)
