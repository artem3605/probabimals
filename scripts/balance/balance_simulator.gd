class_name BalanceSimulator
extends RefCounted

const ComboDetectorScript = preload("res://scripts/scoring/combo_detector.gd")
const ScoringEngineScript = preload("res://scripts/scoring/scoring_engine.gd")

var _combo_detector = ComboDetectorScript.new()
var _scoring_engine = ScoringEngineScript.new()
var _rng := RandomNumberGenerator.new()

func compare_modifier(config: Dictionary) -> Dictionary:
	var modifier_item: Dictionary = config.get("modifier_item", {})
	var mod := Modifier.from_shop_item(modifier_item)
	var modifiers: Array[Modifier] = []
	var extra_rerolls := 0
	if mod != null:
		if mod.effect == Modifier.Effect.ADD_REROLLS:
			extra_rerolls = int(mod.value)
		else:
			modifiers.append(mod)
	var rerolls_per_hand := int(config.get("rerolls_per_hand", 0))

	var baseline := _run_group(config, [] as Array[Modifier], 0)
	var with_modifier := _run_group(config, modifiers, extra_rerolls)
	var deltas := _score_deltas(baseline["scores"], with_modifier["scores"])
	var cost := int(modifier_item.get("cost", 0))
	var modifier_ids: Array[String] = []
	if mod != null:
		modifier_ids.append(mod.id)

	return {
		"simulations": int(config.get("simulations", 1000)),
		"seed": int(config.get("seed", 1)),
		"preset": str(config.get("preset", "custom")),
		"roll_policy": str(config.get("roll_policy", "score_immediately")),
		"rerolls_per_hand": rerolls_per_hand,
		"modified_rerolls_per_hand": rerolls_per_hand + extra_rerolls,
		"modifiers": modifier_ids,
		"baseline_average_score": baseline["average_score"],
		"baseline_combo_distribution": baseline["combo_distribution"],
		"average_score": with_modifier["average_score"],
		"median_score": with_modifier["median_score"],
		"p25_score": with_modifier["p25_score"],
		"p90_score": with_modifier["p90_score"],
		"p95_score": with_modifier["p95_score"],
		"win_rate": with_modifier["win_rate"],
		"combo_distribution": with_modifier["combo_distribution"],
		"modifier_trigger_rates": _trigger_rates(with_modifier["trigger_counts"], with_modifier["hands"]),
		"average_delta_vs_baseline": _average(deltas),
		"median_delta_vs_baseline": _percentile(deltas, 0.5),
		"win_rate_delta_vs_baseline": with_modifier["win_rate"] - baseline["win_rate"],
		"cost_efficiency": _cost_efficiency(_average(deltas), cost),
		"condition_warnings": _condition_warnings(modifier_item),
	}

func run_modifier_report(config: Dictionary) -> Dictionary:
	return compare_modifier(config)

func _run_group(config: Dictionary, modifiers: Array[Modifier], extra_rerolls: int) -> Dictionary:
	var simulations := int(config.get("simulations", 1000))
	var seed_value := int(config.get("seed", 1))
	var target_score := int(config.get("target_score", 150))
	var hands_per_round := int(config.get("hands_per_round", 1))
	var rerolls_per_hand := int(config.get("rerolls_per_hand", 0)) + extra_rerolls
	var roll_policy := str(config.get("roll_policy", "score_immediately"))
	var combo_rules: Array = config.get("combo_rules", [])
	var dice: Array[Die] = _typed_dice(config.get("dice", []))
	var scores: Array[float] = []
	var wins := 0
	var combo_distribution := {}
	var trigger_counts := {}

	_combo_detector.set_combo_rules(combo_rules)
	_rng.seed = seed_value

	for _i in range(simulations):
		var total_score := 0
		for _hand_i in range(hands_per_round):
			var rolled_faces := _roll_hand(dice, roll_policy, rerolls_per_hand)
			var combo := _combo_detector.detect_best_combo(rolled_faces)
			var score_data := _scoring_engine.calculate_score(combo, rolled_faces, combo.get("in_combo", []), modifiers)
			total_score += int(score_data.get("total", 0))
			var combo_type := str(combo.get("type", "none"))
			combo_distribution[combo_type] = int(combo_distribution.get(combo_type, 0)) + 1
			for modifier in modifiers:
				if modifier.applies_to_combo(combo_type):
					trigger_counts[modifier.id] = int(trigger_counts.get(modifier.id, 0)) + 1
				else:
					trigger_counts[modifier.id] = int(trigger_counts.get(modifier.id, 0))

		scores.append(float(total_score))
		if total_score >= target_score:
			wins += 1

	return {
		"hands": simulations * hands_per_round,
		"scores": scores,
		"average_score": _average(scores),
		"median_score": _percentile(scores, 0.5),
		"p25_score": _percentile(scores, 0.25),
		"p90_score": _percentile(scores, 0.9),
		"p95_score": _percentile(scores, 0.95),
		"win_rate": float(wins) / float(max(simulations, 1)),
		"combo_distribution": combo_distribution,
		"trigger_counts": trigger_counts,
	}

func _roll_hand(dice: Array[Die], roll_policy: String, rerolls: int) -> Array[DiceFace]:
	var faces := _roll_faces(dice)
	if roll_policy != "greedy_best_combo" and roll_policy != "target_combo":
		return faces

	for _reroll_i in range(rerolls):
		var combo := _combo_detector.detect_best_combo(faces)
		var held: Array = combo.get("in_combo", [])
		if _all_held(held):
			return faces
		faces = _reroll_unheld(dice, faces, held)
	return faces

func _roll_faces(dice: Array[Die]) -> Array[DiceFace]:
	var faces: Array[DiceFace] = []
	for die in dice:
		if die.faces.is_empty():
			continue
		var face_index := _rng.randi_range(0, die.faces.size() - 1)
		faces.append(die.faces[face_index].duplicate_face())
	return faces

func _reroll_unheld(dice: Array[Die], current_faces: Array[DiceFace], held: Array) -> Array[DiceFace]:
	var faces: Array[DiceFace] = []
	for i in range(current_faces.size()):
		if i < held.size() and bool(held[i]):
			faces.append(current_faces[i].duplicate_face())
		else:
			var die := dice[i]
			var face_index := _rng.randi_range(0, die.faces.size() - 1)
			faces.append(die.faces[face_index].duplicate_face())
	return faces

func _all_held(held: Array) -> bool:
	if held.is_empty():
		return false
	for value in held:
		if not bool(value):
			return false
	return true

func _typed_dice(raw_dice: Array) -> Array[Die]:
	var dice: Array[Die] = []
	for die in raw_dice:
		if die is Die:
			dice.append(die.duplicate_die())
	return dice

func _condition_warnings(item: Dictionary) -> Array[String]:
	var warnings: Array[String] = []
	var description := str(item.get("description", "")).to_lower()
	var params: Dictionary = item.get("params", {})
	var condition := str(params.get("condition", ""))
	if description.contains("or better") and not condition.is_empty():
		warnings.append("%s description says 'or better', but current condition matching is exact." % str(item.get("id", "")))
	return warnings

func _trigger_rates(trigger_counts: Dictionary, hands: int) -> Dictionary:
	var result := {}
	for modifier_id in trigger_counts:
		result[modifier_id] = float(trigger_counts[modifier_id]) / float(max(hands, 1))
	return result

func _score_deltas(baseline_scores: Array, modifier_scores: Array) -> Array[float]:
	var deltas: Array[float] = []
	var count = min(baseline_scores.size(), modifier_scores.size())
	for i in range(count):
		deltas.append(float(modifier_scores[i]) - float(baseline_scores[i]))
	return deltas

func _average(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for value in values:
		total += float(value)
	return total / float(values.size())

func _percentile(values: Array, percentile: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted_values := values.duplicate()
	sorted_values.sort()
	var index := int(floor(clamp(percentile, 0.0, 1.0) * float(sorted_values.size() - 1)))
	return float(sorted_values[index])

func _cost_efficiency(delta: float, cost: int) -> float:
	if cost <= 0:
		return 0.0
	return delta / float(cost)
