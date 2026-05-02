class_name Modifier
extends RefCounted

enum Effect { BONUS, ADD_MULT, X_MULT, ADD_REROLLS }

var id: String
var name: String
var effect: Effect
var value: float
var condition: String
var rarity: String


func _init(
	p_id: String, p_name: String, p_effect: Effect, p_value: float, p_condition: String, p_rarity: String
) -> void:
	id = p_id
	name = p_name
	effect = p_effect
	value = p_value
	condition = p_condition
	rarity = p_rarity


func applies_to_combo(combo_type: String) -> bool:
	if condition.is_empty() or condition == "always":
		return true
	return condition == combo_type


static func from_shop_item(item: Dictionary) -> Modifier:
	var params: Dictionary = item.get("params", {})
	var effect_enum := effect_from_string(str(params.get("effect", "")))
	if effect_enum == -1:
		return null
	var default_value := _default_value_for_effect(effect_enum)
	return (
		Modifier
		. new(
			str(item.get("id", "")),
			str(item.get("name", "")),
			effect_enum,
			float(params.get("value", default_value)),
			str(params.get("condition", "")),
			str(item.get("rarity", "common")),
		)
	)


static func from_save_dict(d: Dictionary) -> Modifier:
	var effect_enum := effect_from_string(str(d.get("effect", "")))
	if effect_enum == -1:
		return null
	var default_value := _default_value_for_effect(effect_enum)
	return (
		Modifier
		. new(
			str(d.get("id", "")),
			str(d.get("name", "")),
			effect_enum,
			float(d.get("value", default_value)),
			str(d.get("condition", "")),
			str(d.get("rarity", "common")),
		)
	)


func to_save_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"effect": effect_to_string(effect),
		"value": value,
		"condition": condition,
		"rarity": rarity,
	}


## Returns -1 if the string is not a recognised effect. Callers must handle this before passing to _init.
static func effect_from_string(s: String) -> int:
	match s:
		"bonus":
			return Effect.BONUS
		"add_mult":
			return Effect.ADD_MULT
		"x_mult":
			return Effect.X_MULT
		"add_rerolls":
			return Effect.ADD_REROLLS
		_:
			return -1


static func _default_value_for_effect(effect_enum: int) -> float:
	if effect_enum == Effect.X_MULT:
		return 1.0
	if effect_enum == Effect.ADD_REROLLS:
		return 1.0
	return 0.0


static func effect_to_string(e: Effect) -> String:
	match e:
		Effect.BONUS:
			return "bonus"
		Effect.ADD_MULT:
			return "add_mult"
		Effect.X_MULT:
			return "x_mult"
		Effect.ADD_REROLLS:
			return "add_rerolls"
	return ""
