class_name gdserde

static var _field_list_cache := {
	&"Node3D": [
		Field.native(&"transform", TYPE_TRANSFORM3D),
	],
	# TODO: Add more as needed
}


static func _field_str(obj: Object, field: Field) -> String:
	return str(util.get_or_default(obj, &"gdserde_class", &"(?)"), ".", field.name)


class Result:
	var value: Variant
	var err: String
	var _stack: Array


	func expect_ok() -> void:
		if err:
			push_error(err)
			if _stack:
				print("gdserde error: ", err)
				util.print_saved_stack(_stack, 1)
			assert(false, str(err, " (see console for full stack trace)"))


	func _init(value_: Variant, err_: String) -> void:
		value = value_
		err = err_
		if err:
			_stack = get_stack() # NOTE: Debug-only by default


	static func ok(value_: Variant) -> Result:
		return Result.new(value_, "")


	static func fail(...args: Array) -> Result:
		var msg: String = str.callv(args)
		return Result.new(null, msg)


class Spec:
	var type: Variant.Type
	var object_class: GDScript
	var inner: Spec
	var key_type: Variant.Type


	func _init(type_: Variant.Type) -> void:
		type = type_


	static func native(type_: Variant.Type) -> Spec:
		return Spec.new(type_)


	static func object(object_class_: GDScript) -> Spec:
		var spec := Spec.new(TYPE_OBJECT)
		spec.object_class = object_class_
		return spec


	static func array(inner_: Spec) -> Spec:
		var spec := Spec.new(TYPE_ARRAY)
		spec.inner = inner_
		return spec


	static func dict(key_type_: Variant.Type, inner_: Spec) -> Spec:
		var spec := Spec.new(TYPE_DICTIONARY)
		spec.inner = inner_
		spec.key_type = key_type_
		return spec


class Field:
	var name: StringName
	var spec: Spec
	var is_optional := false


	func _init(name_: StringName, spec_: Spec) -> void:
		name = name_
		spec = spec_


	func optional() -> Field:
		is_optional = true
		return self


	static func native(name_: StringName, type: Variant.Type) -> Field:
		return Field.new(name_, Spec.new(type))


static func _create_obj_fields(obj: Object) -> Array[Field]:
	var fields: Array[Field] = []
	if obj.has_method(&"gdserde_fields"):
		fields = obj.call(&"gdserde_fields")
	elif util.has_member(obj, &"gdserde_props"):
		for p: StringName in obj.get(&"gdserde_props"):
			fields.push_back(Field.native(p, typeof(obj.get(p))))
	elif obj.get_class() != "RefCounted":
		assert(false, str("Object must define `static func gdserde_fields()`: ", obj))

	if not fields:
		for item in obj.get_property_list():
			var name: String = item["name"]
			match name:
				"RefCounted", "script", "Script Variables", "__meta__", "Built-in script":
					continue

			var type: Variant.Type = item["type"]
			fields.push_back(Field.native(name, type))

	# Sanity check
	if OS.is_debug_build():
		for field in fields:
			assert(
				util.has_member_nullable(obj, field.name),
				str(
					"Missing field '",
					_field_str(obj, field),
					"', actual fields: ",
					util.get_field_names(obj),
				),
			)
			assert(
				obj.get(field.name) != null,
				str(
					"Field '",
					_field_str(obj, field),
					"', is null (even optionals cannot be null--add a default object)",
				),
			)
			assert(
				field.spec.type == typeof(obj.get(field.name)),
				str(
					_field_str(obj, field),
					" ",
					util.msg_unexpected_type(field.spec.type, obj.get(field.name)),
				),
			)

	return fields


static func _get_obj_fields(obj: Object) -> Array[Field]:
	var fields: Array[Field] = []

	if obj.get_script():
		if util.has_member(obj, &"gdserde_class"):
			var gdserde_class: StringName = obj.get(&"gdserde_class")
			if _field_list_cache.has(gdserde_class):
				var arr: Array = _field_list_cache[gdserde_class]
				fields.assign(arr)
			else:
				fields = _create_obj_fields(obj)
				_field_list_cache[gdserde_class] = fields
		else:
			push_warning("Unoptimized class: ", obj)
			fields = _create_obj_fields(obj)

	else:
		var obj_class := StringName(obj.get_class())
		while obj_class and not _field_list_cache.has(obj_class):
			obj_class = ClassDB.get_parent_class(obj_class)
		if _field_list_cache.has(obj_class):
			var arr: Array = _field_list_cache[obj_class]
			fields.assign(arr)
		else:
			assert(false, str("Unhandled class, add to gdserde._field_list_cache: ", obj_class))
			fields = _create_obj_fields(obj)

	return fields


static func _is_packed_array_type(type: Variant.Type) -> bool:
	match type:
		TYPE_PACKED_BYTE_ARRAY, \
		TYPE_PACKED_INT32_ARRAY, \
		TYPE_PACKED_INT64_ARRAY, \
		TYPE_PACKED_FLOAT32_ARRAY, \
		TYPE_PACKED_FLOAT64_ARRAY, \
		TYPE_PACKED_STRING_ARRAY, \
		TYPE_PACKED_VECTOR2_ARRAY, \
		TYPE_PACKED_VECTOR3_ARRAY, \
		TYPE_PACKED_COLOR_ARRAY, \
		TYPE_PACKED_VECTOR4_ARRAY:
			return true
		_:
			return false


static func _get_packed_inner_type(type: Variant.Type) -> Variant.Type:
	match type:
		TYPE_PACKED_BYTE_ARRAY:
			return TYPE_INT
		TYPE_PACKED_INT32_ARRAY:
			return TYPE_INT
		TYPE_PACKED_INT64_ARRAY:
			return TYPE_INT
		TYPE_PACKED_FLOAT32_ARRAY:
			return TYPE_FLOAT
		TYPE_PACKED_FLOAT64_ARRAY:
			return TYPE_FLOAT
		TYPE_PACKED_STRING_ARRAY:
			return TYPE_STRING
		TYPE_PACKED_VECTOR2_ARRAY:
			return TYPE_VECTOR2
		TYPE_PACKED_VECTOR3_ARRAY:
			return TYPE_VECTOR3
		TYPE_PACKED_COLOR_ARRAY:
			return TYPE_COLOR
		TYPE_PACKED_VECTOR4_ARRAY:
			return TYPE_VECTOR4
		_:
			assert(false)
			return TYPE_NIL


static func _get_packed_array_by_type(type: Variant.Type) -> Variant:
	match type:
		TYPE_PACKED_BYTE_ARRAY:
			return PackedByteArray()
		TYPE_PACKED_INT32_ARRAY:
			return PackedInt32Array()
		TYPE_PACKED_INT64_ARRAY:
			return PackedInt64Array()
		TYPE_PACKED_FLOAT32_ARRAY:
			return PackedFloat32Array()
		TYPE_PACKED_FLOAT64_ARRAY:
			return PackedFloat64Array()
		TYPE_PACKED_STRING_ARRAY:
			return PackedStringArray()
		TYPE_PACKED_VECTOR2_ARRAY:
			return PackedVector2Array()
		TYPE_PACKED_VECTOR3_ARRAY:
			return PackedVector3Array()
		TYPE_PACKED_COLOR_ARRAY:
			return PackedColorArray()
		TYPE_PACKED_VECTOR4_ARRAY:
			return PackedVector4Array()
		_:
			assert(false)
			return null


static func deserialize_spec(spec: Spec, variant: Variant) -> Result:
	match spec.type:
		TYPE_OBJECT:
			assert(spec.object_class, "object_class required")
			if variant is not Dictionary:
				return Result.fail(util.msg_unexpected_type(TYPE_DICTIONARY, variant))
			var obj: Object = spec.object_class.new()
			return deserialize_object(obj, variant)
		TYPE_ARRAY:
			assert(spec.inner, "inner required")
			if variant is not Array:
				return Result.fail(util.msg_unexpected_type(TYPE_ARRAY, variant))
			var arr: Array = variant
			var out := []
			for i in arr.size():
				var res := deserialize_spec(spec.inner, arr[i])
				if res.err:
					return Result.fail("index ", i, " ", res.err)
				out.push_back(res.value)
			return Result.ok(out)
		TYPE_DICTIONARY:
			if variant is not Dictionary:
				return Result.fail(util.msg_unexpected_type(TYPE_DICTIONARY, variant))
			var dict: Dictionary = variant
			var out := { }
			for k: Variant in dict:
				if typeof(k) != spec.key_type:
					return Result.fail(util.msg_unexpected_type(spec.key_type, k))
				var res := deserialize_spec(spec.inner, dict[k])
				if res.err:
					return Result.fail("key=", var_to_str(k), " > ", res.err)
				out[k] = res.value
			return Result.ok(out)
		_:
			if _is_packed_array_type(spec.type) and variant is Array:
				var packed_inner := _get_packed_inner_type(spec.type)
				var arr: Array = variant
				var out: Variant = _get_packed_array_by_type(spec.type)
				for i in arr.size():
					var res := deserialize_spec(Spec.native(packed_inner), arr[i])
					if res.err:
						return Result.fail("index ", i, " ", res.err)
					@warning_ignore("unsafe_method_access") # `out` is any PackedArray
					out.push_back(res.value)
				return Result.ok(out)

			if spec.type != typeof(variant):
				return Result.fail(util.msg_unexpected_type(spec.type, variant))

			return Result.ok(variant)


static func deserialize_object(obj: Object, variant: Variant) -> Result:
	if obj.has_method(&"gdserde_deserialize"):
		return obj.call(&"gdserde_deserialize", variant)

	if variant is not Dictionary:
		return Result.fail(util.msg_unexpected_type(TYPE_DICTIONARY, variant))
	var dict: Dictionary = variant

	var fields := _get_obj_fields(obj)
	for field: Field in fields:
		if dict.has(field.name):
			var res: Result

			if field.spec.type != typeof(obj.get(field.name)):
				res = Result.fail(
					str(
						"spec mismatch - ",
						_field_str(obj, field),
						" ",
						util.msg_unexpected_type(field.spec.type, obj.get(field.name)),
					),
				)
				assert(false, res.err)
				return res

			res = deserialize_spec(field.spec, dict[field.name])
			if res.err:
				return Result.fail(_field_str(obj, field), " > ", res.err)

			assert(util.has_member(obj, field.name))
			var target: Variant = obj.get(field.name)
			if target is Array and res.value is Array:
				var target_arr: Array = target
				var res_arr: Array = res.value
				target_arr.assign(res_arr)
			else:
				obj.set(field.name, res.value)
				# This will fail if not exactly the same type
				# e.g. Array != Array[int], even if both are array of ints
				assert(obj.get(field.name) == res.value, str(obj.get(field.name), " ", res.value))
		elif not field.is_optional:
			return Result.fail(_field_str(obj, field), " field name missing from dict: ", dict)

	return Result.ok(obj)


static func serialize(value: Variant) -> Variant:
	if value is Object:
		var obj: Object = value
		return serialize_object(obj)

	if value is Array:
		var out := []
		for x: Variant in value:
			out.push_back(serialize(x))
		return out

	if value is Dictionary:
		var out := { }
		for k: Variant in value:
			out[serialize(k)] = serialize(value[k])
		return out

	return value


static func serialize_object(obj: Object) -> Dictionary:
	if obj.has_method(&"gdserde_serialize"):
		return obj.call(&"gdserde_serialize")

	var dict := { }
	for field: Field in _get_obj_fields(obj):
		dict[field.name] = serialize(obj.get(field.name))
	return dict

#########
# Tests #
#########


class _TestSimpleObj:
	const gdserde_class := &"_TestSimpleObj"
	var my_int: int
	var my_str: String


static func _test_simple_obj_deser() -> void:
	var variant: Variant = {
		"my_int": 5,
		"my_str": "foobar",
	}
	var obj := _TestSimpleObj.new()
	var res := deserialize_object(obj, variant)
	assert(not res.err, res.err)
	assert(obj.my_int == 5)
	assert(obj.my_str == "foobar")


static func _test_simple_obj_ser() -> void:
	var obj := _TestSimpleObj.new()
	obj.my_int = 99
	obj.my_str = "hello"
	var value := serialize_object(obj)
	assert(value.my_int == 99)
	assert(value.my_str == "hello")


class _TestArrayField:
	const gdserde_class := &"_TestArrayField"


	static func gdserde_fields() -> Array[Field]:
		return [
			Field.new(&"strings", Spec.array(Spec.native(TYPE_STRING))),
			Field.new(&"objects", Spec.array(Spec.object(_TestSimpleObj))),
		]


	var strings: Array[String]
	var objects: Array[_TestSimpleObj]


static func _test_array_field_deser() -> void:
	var variant: Variant = {
		"strings": ["foo", "bar"],
		"objects": [{ "my_int": 11, "my_str": "first" }, { "my_int": 22, "my_str": "second" }],
	}

	var obj := _TestArrayField.new()
	var res := deserialize_object(obj, variant)
	assert(not res.err, res.err)
	assert(obj.strings[0] == "foo")
	assert(obj.strings[1] == "bar")
	assert(obj.strings.size() == 2)
	var first: _TestSimpleObj = obj.objects[0]
	assert(first.my_str == "first")
	var second: _TestSimpleObj = obj.objects[1]
	assert(second.my_str == "second")
	assert(obj.objects.size() == 2)


static func _test_array_field_ser() -> void:
	var a := _TestSimpleObj.new()
	a.my_int = 123
	a.my_str = "oatmeal"
	var b := _TestSimpleObj.new()
	b.my_int = 123
	b.my_str = "kirby"

	var obj := _TestArrayField.new()
	obj.strings = ["one", "two"]
	obj.objects = [a, b]

	var value := serialize_object(obj)
	assert(value["strings"][0] == "one")
	assert(value["strings"][1] == "two")
	assert(len(value["strings"]) == 2)
	assert(value["objects"][0]["my_str"] == "oatmeal")
	assert(value["objects"][1]["my_str"] == "kirby")
	assert(len(value["objects"]) == 2)
	assert(typeof(value["objects"][1]) == TYPE_DICTIONARY)


class _TestDictField:
	const gdserde_class := &"_TestDictField"


	static func gdserde_fields() -> Array[Field]:
		return [
			Field.new(&"integer_names", Spec.dict(TYPE_INT, Spec.native(TYPE_STRING))),
			Field.new(&"simple_lookup", Spec.dict(TYPE_STRING, Spec.object(_TestSimpleObj))),
		]


	var integer_names: Dictionary
	var simple_lookup: Dictionary


static func _test_dict_field_deser() -> void:
	var variant: Variant = {
		"integer_names": {
			42: "forty-two",
			-10: "negative ten",
		},
		"simple_lookup": {
			"alpha": { "my_int": 11, "my_str": "eleven" },
			"beta": { "my_int": 22, "my_str": "twenty-two" },
		},
	}

	var obj := _TestDictField.new()
	var res := deserialize_object(obj, variant)
	assert(not res.err, res.err)
	assert(obj.integer_names[42] == "forty-two")
	assert(obj.integer_names[-10] == "negative ten")
	var a: _TestSimpleObj = obj.simple_lookup["alpha"]
	assert(a.my_str == "eleven")
	var b: _TestSimpleObj = obj.simple_lookup["beta"]
	assert(b.my_str == "twenty-two")


static func _test_dict_field_ser() -> void:
	var a := _TestSimpleObj.new()
	a.my_int = -99
	a.my_str = "qux"
	var b := _TestSimpleObj.new()
	b.my_int = 99
	b.my_str = "cruft"

	var obj := _TestDictField.new()
	obj.integer_names = {
		0x11: "onety-one",
		0xF5: "fleventy-five",
	}
	obj.simple_lookup = {
		"quebec": a,
		"charlie": b,
	}

	var value := serialize_object(obj)
	assert(value["integer_names"][0xF5] == "fleventy-five")
	assert(value["simple_lookup"]["charlie"]["my_int"] == 99)
	assert(value["simple_lookup"]["charlie"] is Dictionary)


class _TestOptionalField:
	const gdserde_class := &"_TestOptionalField"


	static func gdserde_fields() -> Array[Field]:
		return [
			Field.native(&"my_int", TYPE_INT).optional(),
			Field.native(&"my_str", TYPE_STRING).optional(),
		]


	var my_int: int = 10
	var my_str: String = "nothing"


static func _test_optional_deser() -> void:
	if true:
		var variant := { "my_int": 5 }
		var obj := _TestOptionalField.new()
		var res := deserialize_object(obj, variant)
		assert(not res.err, res.err)
		assert(obj.my_int == 5)
		assert(obj.my_str == "nothing")

	if true:
		var variant := { "my_str": "something" }
		var obj := _TestOptionalField.new()
		var res := deserialize_object(obj, variant)
		assert(not res.err, res.err)
		assert(obj.my_int == 10)
		assert(obj.my_str == "something")


class _TestPackedArrayField:
	const gdserde_class := &"_TestPackedArrayField"


	static func gdserde_fields() -> Array[Field]:
		return [
			Field.native(&"vectors", TYPE_PACKED_VECTOR2_ARRAY),
			Field.new(&"sentences", Spec.array(Spec.native(TYPE_PACKED_STRING_ARRAY))),
		]


	var vectors: PackedVector2Array
	var sentences: Array[PackedStringArray]


static func _test_packed_array_deser() -> void:
	if true:
		# JSON-compatible types
		var variant := {
			"vectors": [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT],
			"sentences": [["Run", "and", "jump"], ["Duck", "and", "dodge"]],
		}
		var obj := _TestPackedArrayField.new()
		var res := deserialize_object(obj, variant)
		assert(not res.err, res.err)
		assert(obj.vectors[3] == Vector2.RIGHT)
		assert(obj.sentences[1][2] == "dodge")
		assert(typeof(obj.sentences[1]) == TYPE_PACKED_STRING_ARRAY)

	if true:
		# native packed array types
		var variant := {
			"vectors": PackedVector2Array([Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]),
			"sentences": [
				PackedStringArray(["Run", "and", "jump"]),
				PackedStringArray(["Duck", "and", "dodge"]),
			],
		}
		var obj := _TestPackedArrayField.new()
		var res := deserialize_object(obj, variant)
		assert(not res.err, res.err)
		assert(obj.vectors[3] == Vector2.RIGHT)
		assert(obj.sentences[1][2] == "dodge")
		assert(typeof(obj.sentences[1]) == TYPE_PACKED_STRING_ARRAY)


static func _test_node3d() -> void:
	var node1 := Marker3D.new() # Subclass of Node3D
	node1.transform.origin = Vector3(1, 2, 3)

	var variant: Variant = serialize(node1)

	var node2 := Marker3D.new()
	var res := deserialize_object(node2, variant)
	assert(not res.err, res.err)
	assert(node2.transform.origin == Vector3(1, 2, 3))

	node1.free()
	node2.free()


static func _static_init() -> void:
	if OS.is_debug_build():
		_tests()


static func _tests() -> void:
	_test_simple_obj_deser()
	_test_simple_obj_ser()
	_test_array_field_deser()
	_test_array_field_ser()
	_test_dict_field_deser()
	_test_dict_field_ser()
	_test_optional_deser()
	_test_packed_array_deser()
	_test_node3d()
	print("gdserde tests PASSED")
