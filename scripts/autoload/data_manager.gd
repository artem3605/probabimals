extends Node

var _symbols: Array = []
var _parts: Array = []
var _scoring_rules: Dictionary = {}
var _symbol_map: Dictionary = {}


func _ready() -> void:
	_load_symbols()
	_load_parts()
	_load_scoring_rules()


func _load_symbols() -> void:
	var file := FileAccess.open("res://resources/data/symbols.json", FileAccess.READ)
	if file:
		var json := JSON.new()
		var error := json.parse(file.get_as_text())
		if error == OK:
			_symbols = json.data
			for symbol in _symbols:
				_symbol_map[symbol["id"]] = symbol


func _load_parts() -> void:
	var file := FileAccess.open("res://resources/data/parts.json", FileAccess.READ)
	if file:
		var json := JSON.new()
		var error := json.parse(file.get_as_text())
		if error == OK:
			_parts = json.data


func _load_scoring_rules() -> void:
	var file := FileAccess.open("res://resources/data/scoring_rules.json", FileAccess.READ)
	if file:
		var json := JSON.new()
		var error := json.parse(file.get_as_text())
		if error == OK:
			_scoring_rules = json.data


func get_all_symbols() -> Array:
	return _symbols


func get_symbol(id: String) -> Dictionary:
	return _symbol_map.get(id, {})


func get_all_parts() -> Array[PartData]:
	var result: Array[PartData] = []
	for data in _parts:
		result.append(PartData.from_dict(data))
	return result


func get_scoring_rules() -> Dictionary:
	return _scoring_rules


func get_shop_catalogue() -> Array[PartData]:
	return get_all_parts()
