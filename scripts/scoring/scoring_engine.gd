class_name ScoringEngine
extends RefCounted

var rules: Dictionary = {}


func _init(scoring_rules: Dictionary = {}) -> void:
	rules = scoring_rules


func calculate_spin_score(results: Array[String], machine: Machine) -> Dictionary:
	var base_points := 0
	var matches: Array[Dictionary] = []

	# Count occurrences of each symbol
	var counts: Dictionary = {}
	for symbol_id in results:
		counts[symbol_id] = counts.get(symbol_id, 0) + 1

	# Evaluate matches
	for symbol_id in counts:
		var count: int = counts[symbol_id]
		var symbol_data: Dictionary = DataManager.get_symbol(symbol_id)
		var value: int = symbol_data.get("value", 0)

		if count == 3:
			var mult: float = rules.get("three_of_a_kind_multiplier", 3.0)
			var points := int(value * mult)
			base_points += points
			matches.append({"symbol": symbol_id, "count": 3, "points": points})
		elif count == 2:
			var mult: float = rules.get("two_of_a_kind_multiplier", 1.0)
			var points := int(value * mult)
			base_points += points
			matches.append({"symbol": symbol_id, "count": 2, "points": points})

	var multiplier: float = machine.get_score_multiplier() if machine else 1.0
	var total := int(base_points * multiplier)

	return {
		"base_points": base_points,
		"multiplier": multiplier,
		"total": total,
		"matches": matches,
	}
