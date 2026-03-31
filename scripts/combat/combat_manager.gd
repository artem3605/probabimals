class_name CombatManager
extends Node

enum HandState { HAND_ACTIVE, HAND_TRANSITION, COMBAT_ENDED }

signal dice_rolled(values: Array[int])
signal die_held(index: int, held: bool)
signal hand_scored(combo: Dictionary, score_data: Dictionary)
signal combat_ended(final_score: int, target_beaten: bool)
signal rerolls_changed(remaining: int)
signal hands_changed(remaining: int)

var hands_remaining: int = 4
var rerolls_remaining: int = 2
var current_roll: Array[DiceFace] = []
var held_dice: Array[bool] = [false, false, false, false, false]
var running_score: int = 0
var target_score: int = 150
var active_dice: Array[Die] = []
var combo_detector := ComboDetector.new()
var combo_odds_helper := ComboOddsHelper.new()
var scoring_engine := ScoringEngine.new()
var probability_snapshot: Dictionary = {}
var has_rolled: bool = false
var hand_state: HandState = HandState.HAND_ACTIVE
var _combo_rules: Array = []
var _rerolls_reset_value: int = 2
var _roll_provider: Callable = Callable()
var _roll_number: int = 0

func start_combat(dice: Array[Die], target: int, hands: int, rerolls: int,
		combo_rules: Array = [], reroll_reset_value: int = -1,
		roll_provider: Callable = Callable()) -> void:
	active_dice = dice
	target_score = target
	hands_remaining = hands
	rerolls_remaining = rerolls
	_rerolls_reset_value = reroll_reset_value if reroll_reset_value >= 0 else rerolls
	_roll_provider = roll_provider
	_roll_number = 0
	running_score = 0
	current_roll.clear()
	has_rolled = false
	hand_state = HandState.HAND_ACTIVE
	_reset_held()
	_combo_rules = combo_rules.duplicate(true)
	combo_detector.set_combo_rules(_combo_rules)
	_refresh_probability_snapshot()

func roll_dice() -> void:
	if not can_roll():
		return
	rerolls_remaining -= 1
	rerolls_changed.emit(rerolls_remaining)
	has_rolled = true
	var scripted_values: Array[int] = []
	if _roll_provider.is_valid():
		scripted_values = _to_int_array(_roll_provider.call(_roll_number, held_dice.duplicate()))

	for i in range(active_dice.size()):
		if not held_dice[i]:
			var face: DiceFace
			if not scripted_values.is_empty() and i < scripted_values.size():
				face = DiceFace.make_basic(scripted_values[i])
			else:
				face = active_dice[i].roll()
			if i < current_roll.size():
				current_roll[i] = face
			else:
				current_roll.append(face)

	_roll_number += 1
	_refresh_probability_snapshot()
	dice_rolled.emit(current_roll_values())

func current_roll_values() -> Array[int]:
	var vals: Array[int] = []
	for f in current_roll:
		vals.append(f.value)
	return vals

func hold_die(index: int) -> void:
	if index >= 0 and index < held_dice.size() and has_rolled:
		held_dice[index] = true
		_refresh_probability_snapshot()
		die_held.emit(index, true)

func unhold_die(index: int) -> void:
	if index >= 0 and index < held_dice.size():
		held_dice[index] = false
		_refresh_probability_snapshot()
		die_held.emit(index, false)

func toggle_hold(index: int) -> void:
	if index >= 0 and index < held_dice.size() and has_rolled:
		held_dice[index] = not held_dice[index]
		_refresh_probability_snapshot()
		die_held.emit(index, held_dice[index])

func is_held(index: int) -> bool:
	if index >= 0 and index < held_dice.size():
		return held_dice[index]
	return false

func get_current_combo() -> Dictionary:
	if current_roll.size() == 0:
		return {}
	return combo_detector.detect_best_combo(current_roll)

func get_probability_snapshot() -> Dictionary:
	return probability_snapshot.duplicate(true)

func score_hand(modifiers: Array) -> Dictionary:
	if not can_score():
		return {}
	var combo := get_current_combo()
	if combo.is_empty():
		return {}

	var in_combo: Array[bool] = combo.get("in_combo", [])
	var score_data := scoring_engine.calculate_score(combo, current_roll, in_combo, modifiers)
	running_score += score_data["total"]
	hands_remaining -= 1
	hands_changed.emit(hands_remaining)

	var result := {
		"combo": combo,
		"score_data": score_data,
		"running_score": running_score,
	}
	hand_scored.emit(combo, score_data)

	if hands_remaining <= 0 or running_score >= target_score:
		hand_state = HandState.COMBAT_ENDED
	else:
		hand_state = HandState.HAND_TRANSITION

	has_rolled = false
	rerolls_remaining = _rerolls_reset_value
	rerolls_changed.emit(rerolls_remaining)
	_reset_held()
	current_roll.clear()
	_refresh_probability_snapshot()

	if hand_state == HandState.COMBAT_ENDED:
		end_combat()

	return result

func begin_next_hand() -> void:
	if hand_state != HandState.HAND_TRANSITION:
		return
	hand_state = HandState.HAND_ACTIVE

func end_combat() -> void:
	combat_ended.emit(running_score, running_score >= target_score)

func can_roll() -> bool:
	return hand_state == HandState.HAND_ACTIVE and rerolls_remaining > 0

func can_score() -> bool:
	return hand_state == HandState.HAND_ACTIVE and has_rolled and current_roll.size() > 0

func _reset_held() -> void:
	held_dice = [false, false, false, false, false]

func _refresh_probability_snapshot() -> void:
	probability_snapshot = combo_odds_helper.calculate_probabilities(
		current_roll,
		held_dice,
		_combo_rules,
		_build_die_face_options()
	)

func _build_die_face_options() -> Array:
	var die_face_options: Array = []
	for die in active_dice:
		var options: Array[DiceFace] = []
		for face in die.faces:
			options.append(face.duplicate_face())
		die_face_options.append(options)
	return die_face_options


func _to_int_array(raw: Variant) -> Array[int]:
	var result: Array[int] = []
	if raw is Array:
		for value in raw:
			result.append(int(value))
	return result
