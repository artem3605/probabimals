class_name ComboDetector
extends RefCounted

var _combo_rules: Array = []
var _rules_by_type: Dictionary = {}

func set_combo_rules(rules: Array) -> void:
	_combo_rules = rules
	_rules_by_type.clear()
	for rule in rules:
		var t: String = rule.get("type", "")
		if t != "":
			_rules_by_type[t] = rule

func detect_best_combo(faces: Array[DiceFace]) -> Dictionary:
	if faces.size() == 0:
		return _make_combo("None", "none", 0.0, -1, [])

	var wild_indices: Array[int] = []
	var fixed_values: Array[int] = []
	for i in range(faces.size()):
		if faces[i].is_wild():
			wild_indices.append(i)
		else:
			fixed_values.append(faces[i].value)

	if wild_indices.is_empty():
		var values: Array[int] = []
		for f in faces:
			values.append(f.value)
		return _detect_from_values(values, faces)

	return _detect_with_wilds(faces, wild_indices)

func _detect_with_wilds(faces: Array[DiceFace], wild_indices: Array[int]) -> Dictionary:
	var base_values: Array[int] = []
	for f in faces:
		base_values.append(f.value)

	var best_combo := _make_combo("None", "none", 0.0, -1, [])
	var best_assignment: Array[int] = base_values.duplicate()

	var assignments := _generate_wild_assignments(wild_indices.size())
	for assignment in assignments:
		var test_values: Array[int] = base_values.duplicate()
		for j in range(wild_indices.size()):
			test_values[wild_indices[j]] = assignment[j]

		var combo := _detect_from_values(test_values, faces)
		if combo.get("priority", -1) > best_combo.get("priority", -1):
			best_combo = combo
			best_assignment = test_values.duplicate()

	# Recompute in_combo with the best assignment
	best_combo["in_combo"] = _compute_in_combo(best_assignment, best_combo)
	return best_combo

func _generate_wild_assignments(count: int) -> Array:
	if count == 0:
		return [[]]
	var result: Array = []
	var sub := _generate_wild_assignments(count - 1)
	for v in range(1, 7):
		for s in sub:
			var a: Array = [v]
			a.append_array(s)
			result.append(a)
	return result

func _detect_from_values(values: Array[int], faces: Array[DiceFace]) -> Dictionary:
	var freq := _count_frequencies(values)
	var sorted_values := values.duplicate()
	sorted_values.sort()

	var checks: Array[String] = []
	if _is_yahtzee(freq):
		checks.append("yahtzee")
	if _is_four_of_a_kind(freq):
		checks.append("four_of_a_kind")
	if _is_large_straight(sorted_values):
		checks.append("large_straight")
	if _is_full_house(freq):
		checks.append("full_house")
	if _is_small_straight(sorted_values):
		checks.append("small_straight")
	if _is_three_of_a_kind(freq):
		checks.append("three_same")
	if _is_two_pair(freq):
		checks.append("two_pair")
	if _is_pair(freq):
		checks.append("pair")
	checks.append("high_card")

	var best_type := checks[0]
	var best_prio := _get_rule_priority(best_type)
	for t in checks:
		var p := _get_rule_priority(t)
		if p > best_prio:
			best_prio = p
			best_type = t
	return _make_combo_from_rule(best_type, values)


func _get_rule_priority(combo_type: String) -> int:
	if _rules_by_type.has(combo_type):
		return int(_rules_by_type[combo_type].get("priority", -1))
	return -1


func _make_combo_from_rule(combo_type: String, values: Array[int]) -> Dictionary:
	var rule: Dictionary = _rules_by_type.get(combo_type, {})
	var combo_name: String = rule.get("name", combo_type)
	var mult: float = float(rule.get("combo_mult", 1.0))
	var prio: int = int(rule.get("priority", 0))
	var in_combo := _compute_in_combo(values, {"type": combo_type, "priority": prio})
	return _make_combo(combo_name, combo_type, mult, prio, in_combo)

func _compute_in_combo(values: Array[int], combo: Dictionary) -> Array[bool]:
	var size := values.size()
	var in_combo: Array[bool] = []
	in_combo.resize(size)
	for i in range(size):
		in_combo[i] = false

	var combo_type: String = combo.get("type", "")

	match combo_type:
		"yahtzee":
			for i in range(size):
				in_combo[i] = true
		"four_of_a_kind":
			_mark_matching(values, 4, in_combo)
		"full_house":
			for i in range(size):
				in_combo[i] = true
		"large_straight":
			for i in range(size):
				in_combo[i] = true
		"small_straight":
			_mark_straight(values, 4, in_combo)
		"three_of_a_kind":
			_mark_matching(values, 3, in_combo)
		"two_pair":
			_mark_two_pair(values, in_combo)
		"pair":
			_mark_matching(values, 2, in_combo)
		"high_card":
			var max_val := -1
			var max_idx := 0
			for i in range(size):
				if values[i] > max_val:
					max_val = values[i]
					max_idx = i
			in_combo[max_idx] = true

	return in_combo

func _mark_matching(values: Array[int], target_count: int, in_combo: Array[bool]) -> void:
	var freq := _count_frequencies(values)
	for val in freq:
		if freq[val] >= target_count:
			var marked := 0
			for i in range(values.size()):
				if values[i] == val and marked < target_count:
					in_combo[i] = true
					marked += 1
			return

func _mark_two_pair(values: Array[int], in_combo: Array[bool]) -> void:
	var freq := _count_frequencies(values)
	var pairs_found := 0
	for val in freq:
		if freq[val] >= 2 and pairs_found < 2:
			var marked := 0
			for i in range(values.size()):
				if values[i] == val and marked < 2:
					in_combo[i] = true
					marked += 1
			pairs_found += 1

func _mark_straight(values: Array[int], length: int, in_combo: Array[bool]) -> void:
	var unique := []
	for v in values:
		if not unique.has(v):
			unique.append(v)
	unique.sort()

	for start_i in range(unique.size() - length + 1):
		var is_seq := true
		for j in range(start_i, start_i + length - 1):
			if unique[j + 1] - unique[j] != 1:
				is_seq = false
				break
		if is_seq:
			var straight_vals := {}
			for j in range(start_i, start_i + length):
				straight_vals[unique[j]] = true
			for i in range(values.size()):
				if straight_vals.has(values[i]):
					in_combo[i] = true
					straight_vals.erase(values[i])
			return

func _count_frequencies(values: Array[int]) -> Dictionary:
	var freq := {}
	for v in values:
		freq[v] = freq.get(v, 0) + 1
	return freq

func _is_yahtzee(freq: Dictionary) -> bool:
	return freq.values().has(5)

func _is_four_of_a_kind(freq: Dictionary) -> bool:
	for count in freq.values():
		if count >= 4:
			return true
	return false

func _is_full_house(freq: Dictionary) -> bool:
	var counts = freq.values()
	counts.sort()
	return counts == [2, 3]

func _is_three_of_a_kind(freq: Dictionary) -> bool:
	for count in freq.values():
		if count >= 3:
			return true
	return false

func _is_two_pair(freq: Dictionary) -> bool:
	var pair_count := 0
	for count in freq.values():
		if count >= 2:
			pair_count += 1
	return pair_count >= 2

func _is_pair(freq: Dictionary) -> bool:
	for count in freq.values():
		if count >= 2:
			return true
	return false

func _is_large_straight(sorted: Array[int]) -> bool:
	var unique := []
	for v in sorted:
		if not unique.has(v):
			unique.append(v)
	if unique.size() < 5:
		return false
	unique.sort()
	return unique[4] - unique[0] == 4

func _is_small_straight(sorted: Array[int]) -> bool:
	var unique := []
	for v in sorted:
		if not unique.has(v):
			unique.append(v)
	unique.sort()
	if unique.size() < 4:
		return false
	for i in range(unique.size() - 3):
		if unique[i + 3] - unique[i] == 3:
			var is_seq := true
			for j in range(i, i + 3):
				if unique[j + 1] - unique[j] != 1:
					is_seq = false
					break
			if is_seq:
				return true
	return false

func _make_combo(combo_name: String, combo_type: String, mult: float,
		prio: int, in_combo_arr: Variant) -> Dictionary:
	return {
		"name": combo_name,
		"type": combo_type,
		"combo_mult": mult,
		"priority": prio,
		"in_combo": in_combo_arr,
	}
