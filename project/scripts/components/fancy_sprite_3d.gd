@tool
class_name FancySprite3D
extends AnimatedSprite3D

@export_tool_button("Flip Frame Horizontal", "PingPongLoop")
var flip_frame_horizontal_tool := _flip_frame_horizontal_tool
@export_tool_button("Reset Data", "Clear")
var reset_data_tool := _reset_data_tool

@export var flip_animations: PackedStringArray
@export var flip_frames: PackedInt32Array


func _ready() -> void:
	util.aok(frame_changed.connect(_on_change_frame))
	util.aok(animation_changed.connect(_on_change_frame))


func _on_change_frame() -> void:
	assert(flip_animations.size() == flip_frames.size())
	for i in flip_frames.size():
		if flip_frames[i] == frame and flip_animations[i] == animation:
			flip_h = true
			return
	flip_h = false


func _toggle_flip_frame(animation_: StringName, frame_: int) -> void:
	var found := false
	for i in flip_frames.size():
		if flip_frames[i] == frame_ and flip_animations[i] == animation_:
			found = true
			flip_frames.remove_at(i)
			flip_animations.remove_at(i)
	if not found:
		util.expect_false(flip_frames.push_back(frame_), str(frame_))
		util.expect_false(flip_animations.push_back(animation_), animation_)

	print("Flipped Frames:")
	for i in flip_frames.size():
		print(str(flip_animations[i], " ", flip_frames[i]))

	_on_change_frame()
	#flip_h = not flip_h


func _toggle_flip_multi(animations: PackedStringArray, frames: PackedInt32Array) -> void:
	assert(animations.size() == frames.size())
	var size := animations.size()
	for i in size:
		_toggle_flip_frame(animations[size - i - 1], frames[size - i - 1])


func _flip_frames_tool(animations: PackedStringArray, frames: PackedInt32Array) -> void:
	if Engine.is_editor_hint():
		print("foo")
		var undo_redo := EditorInterface2.get_editor_undo_redo()
		undo_redo.create_action("Flip Frame")
		undo_redo.add_do_method(self, &"_toggle_flip_multi", animations, frames)
		undo_redo.add_undo_method(self, &"_toggle_flip_multi", animations, frames)
		undo_redo.commit_action()
	else:
		_toggle_flip_multi(animations, frames)


func _flip_frame_horizontal_tool() -> void:
	_flip_frames_tool([animation], [frame])

func _reset_data_tool() -> void:
	var animations: PackedStringArray = []
	var frames: PackedInt32Array = []
	assert(flip_animations.size() == flip_frames.size())
	for i in flip_animations.size():
		util.expect_false(animations.push_back(flip_animations[i]))
		util.expect_false(frames.push_back(flip_frames[i]))
	_flip_frames_tool(animations, frames)
