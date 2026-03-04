extends Node

var _faces: Dictionary = {}
var _shop_catalogue: Array = []
var _combo_rules: Array = []

func _ready() -> void:
	_load_faces()
	_load_shop_catalogue()
	_load_combo_rules()

func _load_json(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open: " + path)
		return null
	var json_string := file.get_as_text()
	file.close()
	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		push_error("JSON parse error in " + path + ": " + json.get_error_message())
		return null
	return json.data

func _load_faces() -> void:
	var data = _load_json("res://resources/data/faces.json")
	if data is Array:
		for entry in data:
			var face := _dict_to_face(entry)
			_faces[face.id] = face

func _load_shop_catalogue() -> void:
	var data = _load_json("res://resources/data/dice_shop.json")
	if data is Array:
		_shop_catalogue = data

func _load_combo_rules() -> void:
	var data = _load_json("res://resources/data/combos.json")
	if data is Array:
		_combo_rules = data

func _dict_to_face(d: Dictionary) -> DiceFace:
	return DiceFace.new(
		str(d.get("id", "")),
		int(d.get("value", 0)),
		DiceFace.type_from_string(str(d.get("face_type", "basic"))),
		float(d.get("effect_value", 0.0)),
		str(d.get("rarity", "common")),
		int(d.get("cost", 0)),
	)

func get_dice_face(id: String) -> DiceFace:
	var face = _faces.get(id)
	if face is DiceFace:
		return face.duplicate_face()
	return null

func get_all_faces() -> Dictionary:
	return _faces

func get_shop_catalogue() -> Array:
	return _shop_catalogue

func get_combo_rules() -> Array:
	return _combo_rules

func create_basic_faces() -> Array[DiceFace]:
	var result: Array[DiceFace] = []
	for v in [1, 2, 3, 4, 5, 6]:
		var face := get_dice_face("face_%d" % v)
		if face:
			result.append(face)
		else:
			result.append(DiceFace.make_basic(v))
	return result
