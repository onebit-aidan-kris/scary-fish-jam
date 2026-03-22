class_name Interactable

static func is_interactable(obj: Object) -> bool:
	return obj.has_signal(&"interacted")


static func _expect_interactable(obj: Object) -> bool:
	if is_interactable(obj):
		return true
	assert(false, str("Object does not implement Interactable trait: ", obj))
	return false


static func interact(obj: Object) -> void:
	if _expect_interactable(obj):
		util.aok(obj.emit_signal(&"interacted"))


static func register(obj: Object, callable: Callable) -> void:
	if _expect_interactable(obj):
		util.aok(obj.connect(&"interacted", callable))
