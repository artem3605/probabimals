class_name CombatManager
extends Node

signal dice_rolled(results: Array[int])
signal die_held(index: int, held: bool)
signal hand_scored(combo: Dictionary, score_data: Dictionary)
signal combat_ended(final_score: int, target_beaten: bool)
signal rerolls_changed(remaining: int)
signal hands_changed(remaining: int)

var hands_remaining: int = 4
var rerolls_remaining: int = 2
var current_roll: Array[int] = []
var held_dice: Array[bool] = [false, false, false, false, false]
var running_score: int = 0
var target_score: int = 150
var active_dice: Array[Die] = []
var combo_detector := ComboDetector.new()
var scoring_engine := ScoringEngine.new()
var has_rolled: bool = false

func start_combat(dice: Array[Die], target: int, hands: int, rerolls: int) -> void:
	active_dice = dice
	target_score = target
	hands_remaining = hands
	rerolls_remaining = rerolls
	running_score = 0
	current_roll.clear()
	has_rolled = false
	_reset_held()

func roll_dice() -> void:
	if rerolls_remaining <= 0:
		return
	rerolls_remaining -= 1
	rerolls_changed.emit(rerolls_remaining)
	has_rolled = true

	for i in range(active_dice.size()):
		if not held_dice[i]:
			if i < current_roll.size():
				current_roll[i] = active_dice[i].roll()
			else:
				current_roll.append(active_dice[i].roll())

	dice_rolled.emit(current_roll.duplicate())

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
	var combo := get_current_combo()
	if combo.is_empty():
		return {}
	var score_data := scoring_engine.calculate_score(combo, current_roll, modifiers)
	running_score += score_data["total"]
	hands_remaining -= 1
	hands_changed.emit(hands_remaining)

	var result := {
		"combo": combo,
		"score_data": score_data,
		"running_score": running_score
	}
	hand_scored.emit(combo, score_data)

	has_rolled = false
	rerolls_remaining = GameManager.rerolls_per_hand
	rerolls_changed.emit(rerolls_remaining)
	_reset_held()
	current_roll.clear()

	if hands_remaining <= 0 or running_score >= target_score:
		end_combat()

	return result

func end_combat() -> void:
	combat_ended.emit(running_score, running_score >= target_score)

func can_roll() -> bool:
	return rerolls_remaining > 0

func can_score() -> bool:
	return has_rolled and current_roll.size() > 0

func _reset_held() -> void:
	held_dice = [false, false, false, false, false]
