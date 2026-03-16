## Workaround for bug: https://github.com/godotengine/godot/issues/91713
## Add more methods as necessary
class_name EditorInterface2

class EditorUndoRedoManager2:
	var _internal: Object


	func _init() -> void:
		assert(Engine.is_editor_hint())
		_internal = Engine.get_singleton("EditorInterface").call(&"get_editor_undo_redo")


	func create_action(
			name: String,
			merge_mode: UndoRedo.MergeMode = UndoRedo.MergeMode.MERGE_DISABLE,
			custom_context: Object = null,
			backward_undo_ops: bool = false,
			mark_unsaved: bool = true,
	) -> void:
		_internal.call(
			&"create_action",
			name,
			merge_mode,
			custom_context,
			backward_undo_ops,
			mark_unsaved,
		)


	func add_do_method(object: Object, method: StringName, ...args: Array) -> void:
		args.push_front(method)
		args.push_front(object)
		_internal.callv(&"add_do_method", args)


	func add_undo_method(object: Object, method: StringName, ...args: Array) -> void:
		args.push_front(method)
		args.push_front(object)
		_internal.callv(&"add_undo_method", args)


	func commit_action() -> void:
		_internal.call(&"commit_action")


static func get_editor_undo_redo() -> EditorUndoRedoManager2:
	return EditorUndoRedoManager2.new()
