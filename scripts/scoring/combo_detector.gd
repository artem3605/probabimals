class_name ComboDetector
extends RefCounted

# Returns the best combo found in the given values
# Result format: {name: String, type: String, base_score: int, multiplier: int, priority: int}
func detect_best_combo(values: Array[int]) -> Dictionary:
	if values.size() == 0:
		return _make_combo("None", "none", 0, 0, -1)

	var freq := _count_frequencies(values)
	var sorted_values := values.duplicate()
	sorted_values.sort()

	# Check from highest priority to lowest
	if _is_yahtzee(freq):
		return _make_combo("Yahtzee", "yahtzee", 100, 8, 8)
	if _is_four_of_a_kind(freq):
		return _make_combo("Four of a Kind", "four_of_a_kind", 80, 5, 7)
	if _is_large_straight(sorted_values):
		return _make_combo("Large Straight", "large_straight", 60, 4, 6)
	if _is_full_house(freq):
		return _make_combo("Full House", "full_house", 50, 3, 5)
	if _is_small_straight(sorted_values):
		return _make_combo("Small Straight", "small_straight", 40, 3, 4)
	if _is_three_of_a_kind(freq):
		return _make_combo("Three of a Kind", "three_of_a_kind", 30, 2, 3)
	if _is_two_pair(freq):
		return _make_combo("Two Pair", "two_pair", 20, 1, 2)
	if _is_pair(freq):
		return _make_combo("Pair", "pair", 10, 1, 1)

	return _make_combo("High Card", "high_card", 5, 1, 0)

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
	# Check all windows of 4 consecutive
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

func _make_combo(combo_name: String, combo_type: String, base: int, mult: int, prio: int) -> Dictionary:
	return {
		"name": combo_name,
		"type": combo_type,
		"base_score": base,
		"multiplier": mult,
		"priority": prio
	}
