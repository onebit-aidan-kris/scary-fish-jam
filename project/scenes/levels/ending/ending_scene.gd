extends Node


func _ready() -> void:
	gamestate.unpause()
	var fade := gamestate.screen_fade
	var rect: ColorRect = fade.get_node("ColorRect")
	rect.modulate.a = 1.0

	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fade.add_child(label)

	label.text = "You survived... for now."
	await get_tree().create_timer(4.0).timeout

	label.text = "Thanks for playing."
	await get_tree().create_timer(3.0).timeout

	gamestate.screen_fade.fade_to_scene("res://scenes/levels/intro/intro_scene.tscn")
