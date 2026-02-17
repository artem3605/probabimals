class_name Reel
extends RefCounted

var base_symbol_weights: Dictionary = {}
var bonus_weights: Dictionary = {}


func get_effective_weights() -> Dictionary:
	var effective := base_symbol_weights.duplicate()
	for symbol_id in bonus_weights:
		if effective.has(symbol_id):
			effective[symbol_id] += bonus_weights[symbol_id]
		else:
			effective[symbol_id] = bonus_weights[symbol_id]
	return effective


func spin() -> String:
	var weights := get_effective_weights()
	var total_weight := 0
	for w in weights.values():
		total_weight += w

	if total_weight <= 0:
		return ""

	var roll := randi() % total_weight
	var cumulative := 0
	for symbol_id in weights:
		cumulative += weights[symbol_id]
		if roll < cumulative:
			return symbol_id
	return weights.keys().back()


func add_symbol(symbol_id: String, weight: int) -> void:
	if bonus_weights.has(symbol_id):
		bonus_weights[symbol_id] += weight
	else:
		bonus_weights[symbol_id] = weight


func modify_weight(symbol_id: String, multiplier: float) -> void:
	if base_symbol_weights.has(symbol_id):
		base_symbol_weights[symbol_id] = int(base_symbol_weights[symbol_id] * multiplier)
