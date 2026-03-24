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
var scoring_engine := ScoringEngine.new()
var has_rolled: bool = false
var hand_state: HandState = HandState.HAND_ACTIVE
var _rerolls_reset_value: int = 2

func start_combat(dice: Array[Die], target: int, hands: int, rerolls: int,
		combo_rules: Array = [], reroll_reset_value: int = -1) -> void:
	active_dice = dice
	target_score = target
	hands_remaining = hands
	rerolls_remaining = rerolls
	_rerolls_reset_value = reroll_reset_value if reroll_reset_value >= 0 else rerolls
	running_score = 0
	current_roll.clear()
	has_rolled = false
	hand_state = HandState.HAND_ACTIVE
	_reset_held()
	combo_detector.set_combo_rules(combo_rules)

func roll_dice() -> void:
	if not can_roll():
		return
	rerolls_remaining -= 1
	rerolls_changed.emit(rerolls_remaining)
	has_rolled = true

	for i in range(active_dice.size()):
		if not held_dice[i]:
			var face := active_dice[i].roll()
			if i < current_roll.size():
				current_roll[i] = face
			else:
				current_roll.append(face)

	dice_rolled.emit(current_roll_values())

func current_roll_values() -> Array[int]:
	var vals: Array[int] = []
	for f in current_roll:
		vals.append(f.value)
	return vals

func hold_die(index: int) -> void:
	if index >= 0 and index < held_dice.size() and has_rolled:
		held_dice[index] = true
		die_held.emit(index, true)

func unhold_die(index: int) -> void:
	if index >= 0 and index < held_dice.size():
		held_dice[index] = false
		die_held.emit(index, false)

func toggle_hold(index: int) -> void:
	if index >= 0 and index < held_dice.size() and has_rolled:
		held_dice[index] = not held_dice[index]
		die_held.emit(index, held_dice[index])

func is_held(index: int) -> bool:
	if index >= 0 and index < held_dice.size():
		return held_dice[index]
	return false

func get_current_combo() -> Dictionary:
	if current_roll.size() == 0:
		return {}
	return combo_detector.detect_best_combo(current_roll)

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

	has_rolled = false
	rerolls_remaining = _rerolls_reset_value
	rerolls_changed.emit(rerolls_remaining)
	_reset_held()
	current_roll.clear()

	if hands_remaining <= 0 or running_score >= target_score:
		hand_state = HandState.COMBAT_ENDED
		end_combat()
	else:
		hand_state = HandState.HAND_TRANSITION

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
