class_name TestData
extends RefCounted

const DETERMINISTIC_DIE = preload("res://tests/support/deterministic_die.gd")
const SHOP_DATA_PATH := "res://resources/data/dice_shop.json"
const COMBO_DATA_PATH := "res://resources/data/combos.json"

static func load_json_array(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Array:
		return parsed.duplicate(true)
	return []

static func load_combo_rules() -> Array:
	return load_json_array(COMBO_DATA_PATH)

static func load_shop_catalogue() -> Array:
	return load_json_array(SHOP_DATA_PATH)

static func find_item_by_id(items: Array, item_id: String) -> Dictionary:
	for item in items:
		if item is Dictionary and item.get("id", "") == item_id:
			return item.duplicate(true)
	return {}

static func basic_face(value: int) -> DiceFace:
	return DiceFace.make_basic(value)

static func face(id: String, value: int, face_type: DiceFace.Type = DiceFace.Type.BASIC,
		effect_value: float = 0.0, rarity: String = "common", cost: int = 0) -> DiceFace:
	return DiceFace.new(id, value, face_type, effect_value, rarity, cost)

static func faces_from_values(values: Array) -> Array[DiceFace]:
	var faces: Array[DiceFace] = []
	for value in values:
		faces.append(basic_face(int(value)))
	return faces

static func die_from_values(values: Array, die_color: String = "colorless",
		die_name: String = "Test Die", description: String = "Test die") -> Die:
	var typed_values: Array[int] = []
	for value in values:
		typed_values.append(int(value))
	return Die.from_values(typed_values, die_color, die_name, description)

static func deterministic_die(roll_values: Array[int], initial_values: Variant = null,
		die_color: String = "colorless", die_name: String = "Test Die",
		description: String = "Deterministic test die") -> Die:
	var initial_faces: Array[DiceFace] = []
	if initial_values is Array:
		var typed_initial_values: Array[int] = []
		for value in initial_values:
			typed_initial_values.append(int(value))
		initial_faces = faces_from_values(typed_initial_values)
	var roll_faces: Array[DiceFace] = faces_from_values(roll_values)
	return DETERMINISTIC_DIE.new(roll_faces, initial_faces, die_color, die_name, description)

static func modifier(effect: String, value: Variant, condition: String = "always",
		id: String = "", name: String = "") -> Dictionary:
	return {
		"id": id,
		"name": name if not name.is_empty() else effect,
		"effect": effect,
		"value": value,
		"condition": condition,
	}
