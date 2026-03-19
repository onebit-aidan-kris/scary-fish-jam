extends CanvasLayer

@onready var health_label: Label = $VBoxContainer/HealthLabel

var boat: Node3D = null


func _ready() -> void:
	boat = get_tree().get_first_node_in_group("player")
	if not boat and boat.has_meta("health"):
		push_error("HUD: player/boat not found or missing health")


func _process(_delta: float) -> void:
	if boat:
		health_label.text = "Health: %.0f" % boat.health
