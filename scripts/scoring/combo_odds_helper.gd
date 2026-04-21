class_name ComboOddsHelper
extends RefCounted

func calculate_probabilities(current_roll: Array[DiceFace], held_dice: Array,
		combo_rules: Array, die_face_options: Array = []) -> Dictionary:
	if current_roll.size() == 0 or current_roll.size() != held_dice.size():
		return {}

	var probabilities := _make_zeroed_probabilities(combo_rules)
	var detector := ComboDetector.new()
	detector.set_combo_rules(combo_rules)

	var working_roll: Array[DiceFace] = []
	for face in current_roll:
		working_roll.append(face.duplicate_face())

	var total_outcomes := _count_outcomes(0, working_roll, held_dice, die_face_options, detector, probabilities)
	if total_outcomes == 0:
		return probabilities

	for combo_type in probabilities.keys():
		probabilities[combo_type] = float(probabilities[combo_type]) / float(total_outcomes)
	return probabilities

func _count_outcomes(index: int, working_roll: Array[DiceFace], held_dice: Array,
		die_face_options: Array, detector: ComboDetector, outcome_counts: Dictionary) -> int:
	if index >= working_roll.size():
		var combo := detector.detect_best_combo(working_roll)
		var combo_type: String = combo.get("type", "")
		if outcome_counts.has(combo_type):
			outcome_counts[combo_type] += 1
		return 1

	if held_dice[index]:
		return _count_outcomes(index + 1, working_roll, held_dice, die_face_options, detector, outcome_counts)

	var total_outcomes := 0
	for face: DiceFace in _get_face_options_for_die(index, die_face_options):
		working_roll[index] = face.duplicate_face()
		total_outcomes += _count_outcomes(index + 1, working_roll, held_dice, die_face_options, detector, outcome_counts)
	return total_outcomes

func _get_face_options_for_die(index: int, die_face_options: Array) -> Array[DiceFace]:
	if index < die_face_options.size() and die_face_options[index] is Array and not die_face_options[index].is_empty():
		var custom_options: Array[DiceFace] = []
		for face: DiceFace in die_face_options[index]:
			custom_options.append(face)
		return custom_options

	var default_options: Array[DiceFace] = []
	for value in range(1, 7):
		default_options.append(DiceFace.make_basic(value))
	return default_options

func _make_zeroed_probabilities(combo_rules: Array) -> Dictionary:
	var probabilities := {}
	for rule in combo_rules:
		var combo_type: String = rule.get("type", "")
		if not combo_type.is_empty():
			probabilities[combo_type] = 0.0
	return probabilities
