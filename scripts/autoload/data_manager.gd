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
		for face in data:
			_faces[face["id"]] = face

func _load_shop_catalogue() -> void:
	var data = _load_json("res://resources/data/dice_shop.json")
	if data is Array:
		_shop_catalogue = data

func _load_combo_rules() -> void:
	var data = _load_json("res://resources/data/combos.json")
	if data is Array:
		_combo_rules = data

func get_face(id: String) -> Dictionary:
	return _faces.get(id, {})

func get_all_faces() -> Dictionary:
	return _faces

func get_shop_catalogue() -> Array:
	return _shop_catalogue

func get_combo_rules() -> Array:
	return _combo_rules
