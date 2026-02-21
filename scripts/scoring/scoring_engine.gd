class_name ScoringEngine
extends RefCounted

# Modifier format: {id: String, type: String, effect: String, value: float, target_combo: String}
# effect types: "multiply_combo" (multiply a specific combo), "add_rerolls" (extra rerolls), "multiply_all" (multiply everything)
func calculate_score(combo: Dictionary, values: Array[int], modifiers: Array) -> Dictionary:
	var base_score: int = combo.get("base_score", 0)
	var multiplier: int = combo.get("multiplier", 1)

	# Add sum of dice values to base score for non-straight combos
	var dice_sum := 0
	for v in values:
		dice_sum += v
	base_score += dice_sum

	# Apply modifiers
	var mod_mult := 1.0
	for mod in modifiers:
		var effect: String = mod.get("effect", "")
		var target: String = mod.get("target_combo", "")

		if effect == "multiply_combo":
			if target == combo.get("type", "") or target == "all":
				mod_mult *= mod.get("value", 1.0)
		elif effect == "multiply_all":
			mod_mult *= mod.get("value", 1.0)

	var total := int(base_score * multiplier * mod_mult)

	return {
		"base": base_score,
		"multiplier": multiplier,
		"mod_multiplier": mod_mult,
		"total": total
	}
