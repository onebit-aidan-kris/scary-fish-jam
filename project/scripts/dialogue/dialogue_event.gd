class_name DialogueEvent
const gdserde_class = &"DialogueEvent"


static func gdserde_fields() -> Array[gdserde.Field]:
	return [
		gdserde.Field.native(&"conds", TYPE_PACKED_STRING_ARRAY).optional(),
		gdserde.Field.native(&"speaker", TYPE_STRING).optional(),
		gdserde.Field.native(&"text", TYPE_PACKED_STRING_ARRAY).optional(),
		gdserde.Field.native(&"next", TYPE_PACKED_STRING_ARRAY).optional(),
		gdserde.Field.new(
			&"choices",
			gdserde.Spec.array(gdserde.Spec.object(DialogueChoice)),
		).optional(),
		gdserde.Field.new(&"callback", gdserde.Spec.object(DialogueCallback)).optional(),
		gdserde.Field.new(
			&"sequence",
			gdserde.Spec.array(gdserde.Spec.object(DialogueSequenceEntry)),
		).optional(),
	]


var conds: PackedStringArray
var speaker: String
var text: PackedStringArray
var next: PackedStringArray
var choices: Array[DialogueChoice]
var callback := DialogueCallback.new()
var sequence: Array[DialogueSequenceEntry]


class DialogueCallback:
	const gdserde_class = &"DialogueCallback"


	static func gdserde_fields() -> Array[gdserde.Field]:
		return [
			gdserde.Field.native(&"name", TYPE_STRING),
			gdserde.Field.native(&"args", TYPE_PACKED_STRING_ARRAY).optional(),
		]


	var name: String
	var args: PackedStringArray


class DialogueChoice:
	const gdserde_class = &"DialogueChoice"


	static func gdserde_fields() -> Array[gdserde.Field]:
		return [
			gdserde.Field.native(&"text", TYPE_STRING),
			gdserde.Field.native(&"next", TYPE_STRING),
			gdserde.Field.new(&"callback", gdserde.Spec.object(DialogueCallback)).optional(),
		]


	var text: String
	var next: String
	var callback := DialogueCallback.new()


class DialogueSequenceEntry:
	const gdserde_class = &"DialogueSequenceEntry"


	static func gdserde_fields() -> Array[gdserde.Field]:
		return [
			gdserde.Field.native(&"speaker", TYPE_STRING).optional(),
			gdserde.Field.native(&"text", TYPE_PACKED_STRING_ARRAY),
		]


	var speaker: String
	var text: PackedStringArray
