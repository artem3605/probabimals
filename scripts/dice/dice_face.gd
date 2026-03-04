class_name DiceFace
extends RefCounted

enum Type { BASIC, PIP, MULT, XMULT, WILD }

var id: String = ""
var value: int = 0
var face_type: Type = Type.BASIC
var effect_value: float = 0.0
var rarity: String = "common"
var cost: int = 0

func _init(p_id: String = "", p_value: int = 0, p_type: Type = Type.BASIC,
		p_effect: float = 0.0, p_rarity: String = "common", p_cost: int = 0) -> void:
	id = p_id
	value = p_value
	face_type = p_type
	effect_value = p_effect
	rarity = p_rarity
	cost = p_cost

func get_combo_value() -> int:
	if face_type == Type.WILD:
		return -1
	return value

func get_face_sum_contribution() -> float:
	var base := float(value)
	if face_type == Type.PIP:
		base += effect_value
	return base

func get_add_mult() -> float:
	if face_type == Type.MULT:
		return effect_value
	return 0.0

func get_x_mult() -> float:
	if face_type == Type.XMULT:
		return effect_value
	return 1.0

func is_wild() -> bool:
	return face_type == Type.WILD

func duplicate_face() -> DiceFace:
	return DiceFace.new(id, value, face_type, effect_value, rarity, cost)

static func type_from_string(s: String) -> Type:
	match s.to_lower():
		"pip": return Type.PIP
		"mult": return Type.MULT
		"xmult": return Type.XMULT
		"wild": return Type.WILD
		_: return Type.BASIC

static func make_basic(p_value: int) -> DiceFace:
	return DiceFace.new("face_%d" % p_value, p_value, Type.BASIC)
