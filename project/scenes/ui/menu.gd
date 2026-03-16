class_name Menu
extends CanvasLayer

enum SpecKind {
	NONE,
	BUTTON,
	CHECKBOX,
	LABEL,
}


## Menu item builder
class Spec:
	var _node: Control
	var _kind: SpecKind = SpecKind.NONE
	var _text: String
	var _callback: Callable
	var _action: StringName = &""
	var _button_pressed: bool = false
	var _focus: bool = false
	var _hidden: bool = false
	var _visible_when: Callable


	func action(action_: StringName) -> Spec:
		_action = action_
		return self


	func focus(value: bool = true) -> Spec:
		_focus = value
		return self


	func toggled(value: bool = true) -> Spec:
		_button_pressed = value
		return self


	func visible_when(callback: Callable) -> Spec:
		_visible_when = callback
		return self


	func debug_only() -> Spec:
		if not OS.is_debug_build():
			_hidden = true
		return self


	func desktop_only() -> Spec:
		if not OS.has_feature("pc"):
			_hidden = true
		return self

# Menu item factory functions


static func button(text: String, callback: Callable) -> Spec:
	var spec := Spec.new()
	spec._kind = SpecKind.BUTTON
	spec._text = text
	spec._callback = callback
	return spec


static func checkbox(text: String, callback: Callable) -> Spec:
	var spec := Spec.new()
	spec._kind = SpecKind.CHECKBOX
	spec._text = text
	spec._callback = callback
	return spec


static func label(text: String) -> Spec:
	var spec := Spec.new()
	spec._kind = SpecKind.LABEL
	spec._text = text
	return spec

# Menu instance

@onready var background: ColorRect = %Background
@onready var title_label: Label = %Title

@onready var _items_container: Node = %ItemsContainer
@onready var _templates := {
	SpecKind.BUTTON: %ButtonTemplate,
	SpecKind.CHECKBOX: %CheckBoxTemplate,
	SpecKind.LABEL: %LabelTemplate,
}

var _spec: Array[Spec] = []
var _was_visible_last_frame := false


func _ready() -> void:
	assert(background)
	assert(title_label)
	assert(_items_container)
	title_label.text = ProjectSettings.get_setting("application/config/name")
	hide()
	for k: SpecKind in _templates:
		_get_template(k).hide()

	util.aok(visibility_changed.connect(_on_visibility_changed))


func _process(_delta: float) -> void:
	if _was_visible_last_frame and visible:
		background.visible = get_tree().paused
		for x in _spec:
			if x._action and Input.is_action_just_pressed(x._action):
				x._callback.call()
	_was_visible_last_frame = visible


func _on_visibility_changed() -> void:
	if visible:
		var is_any_focused := false

		for x in _spec:
			if is_instance_valid(x._node) and x._visible_when:
				x._node.visible = x._visible_when.call()

			if x._node.visible and x._node is Button:
				if not is_any_focused or x._focus:
					x._node.grab_focus()
					is_any_focused = true

		assert(is_any_focused)


func _get_template(kind: SpecKind) -> Control:
	assert(_templates.has(kind), str("Missing template for kind: ", kind))
	return _templates[kind]


func _create_item(x: Spec) -> Node:
	var new_node: Control = _get_template(x._kind).duplicate()
	_items_container.add_child(new_node)
	new_node.show()
	x._node = new_node
	return new_node


func build(spec: Array[Spec]) -> void:
	assert(_spec.size() == 0, "TODO: clear old spec")

	for x in spec:
		if x._hidden:
			continue

		match x._kind:
			SpecKind.BUTTON:
				var button_ := _create_item(x) as Button
				button_.text = x._text
				util.aok(button_.pressed.connect(x._callback))
			SpecKind.CHECKBOX:
				var checkbox_ := _create_item(x) as Button
				checkbox_.text = x._text
				checkbox_.toggle_mode = true
				checkbox_.button_pressed = x._button_pressed
				util.aok(checkbox_.toggled.connect(x._callback))
			SpecKind.LABEL:
				var label_ := _create_item(x) as Label
				label_.text = x._text
			_:
				assert(false, str("KIND NOT IMPLEMENTED: ", x._kind))

	_spec = spec
