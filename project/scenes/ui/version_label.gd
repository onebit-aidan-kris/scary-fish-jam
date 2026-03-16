extends Label

func _ready() -> void:
	text = str("v", ProjectSettings.get_setting("application/config/version"))
