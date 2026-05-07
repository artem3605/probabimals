extends Node

var _faces: Dictionary = {}
var _shop_catalogue: Array = []
var _combo_rules: Array = []
var _map_config: Dictionary = {}

const MAP_CONFIG_DEFAULTS := {
	"depth": 10,
	"min_nodes_per_level": 1,
	"max_nodes_per_level": 3,
	"shop_probability": 0.3,
	"max_consecutive_shops": 2,
	"boss_blind_multiplier": 1.5,
}


func _ready() -> void:
	_load_faces()
	_load_shop_catalogue()
	_load_combo_rules()
	_load_map_config()


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


func _load_map_config() -> void:
	var data = _load_json("res://resources/data/map_config.json")
	if data is Dictionary:
		_map_config = _validated_map_config(data)
	else:
		push_error("map_config.json missing or malformed; using defaults")
		_map_config = MAP_CONFIG_DEFAULTS.duplicate()


func _validated_map_config(raw: Dictionary) -> Dictionary:
	var cfg := MAP_CONFIG_DEFAULTS.duplicate()
	for key in MAP_CONFIG_DEFAULTS.keys():
		if raw.has(key):
			cfg[key] = raw[key]

	if int(cfg["depth"]) < 2:
		push_error("map_config.depth must be >= 2; using default")
		cfg["depth"] = MAP_CONFIG_DEFAULTS["depth"]
	if int(cfg["min_nodes_per_level"]) < 1:
		push_error("map_config.min_nodes_per_level must be >= 1; using default")
		cfg["min_nodes_per_level"] = MAP_CONFIG_DEFAULTS["min_nodes_per_level"]
	if int(cfg["max_nodes_per_level"]) < int(cfg["min_nodes_per_level"]):
		push_error("map_config.max_nodes_per_level must be >= min_nodes_per_level; using defaults")
		cfg["min_nodes_per_level"] = MAP_CONFIG_DEFAULTS["min_nodes_per_level"]
		cfg["max_nodes_per_level"] = MAP_CONFIG_DEFAULTS["max_nodes_per_level"]

	var shop_prob := float(cfg["shop_probability"])
	if shop_prob < 0.0 or shop_prob > 1.0:
		push_error("map_config.shop_probability must be in [0,1]; using default")
		cfg["shop_probability"] = MAP_CONFIG_DEFAULTS["shop_probability"]
	if int(cfg["max_consecutive_shops"]) < 0:
		push_error("map_config.max_consecutive_shops must be >= 0; using default")
		cfg["max_consecutive_shops"] = MAP_CONFIG_DEFAULTS["max_consecutive_shops"]
	if float(cfg["boss_blind_multiplier"]) < 1.0:
		push_error("map_config.boss_blind_multiplier must be >= 1.0; using default")
		cfg["boss_blind_multiplier"] = MAP_CONFIG_DEFAULTS["boss_blind_multiplier"]

	return cfg


func _dict_to_face(d: Dictionary) -> DiceFace:
	return (
		DiceFace
		. new(
			str(d.get("id", "")),
			int(d.get("value", 0)),
			DiceFace.type_from_string(str(d.get("face_type", "basic"))),
			float(d.get("effect_value", 0.0)),
			str(d.get("rarity", "common")),
			int(d.get("cost", 0)),
		)
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


func get_map_config() -> Dictionary:
	return _map_config.duplicate()


func create_basic_faces() -> Array[DiceFace]:
	var result: Array[DiceFace] = []
	for v in [1, 2, 3, 4, 5, 6]:
		var face := get_dice_face("face_%d" % v)
		if face:
			result.append(face)
		else:
			result.append(DiceFace.make_basic(v))
	return result
