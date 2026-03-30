extends CanvasLayer

@onready var health_label: Label = $VBoxContainer/HealthLabel

var boat: Node3D = null


func _ready() -> void:
	boat = get_tree().get_first_node_in_group("player")
	if not boat and boat.has_meta("health"):
		push_error("HUD: player/boat not found or missing health")
	health_label.visible = false


func _process(_delta: float) -> void:
	if boat:
		if boat.has_taken_damage and not health_label.visible:
			health_label.visible = true
		if health_label.visible:
			var pct := clampf(boat.health / boat.max_health * 100.0, 0.0, 100.0)
			health_label.text = "Hull Integrity: %.0f%%" % pct
