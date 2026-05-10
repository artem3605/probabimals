class_name TutorialActionFlow
extends RefCounted

const STEP_INTRO_WELCOME := "intro_welcome"
const STEP_INTRO_ROLL := "intro_roll"
const STEP_INTRO_HOLD := "intro_hold"
const STEP_INTRO_REROLL := "intro_reroll"
const STEP_INTRO_PAIR := "intro_pair"
const STEP_INTRO_FINISH := "intro_finish"
const STEP_INTRO_WIN := "intro_win"
const STEP_SHOP_INTRO := "shop_intro"
const STEP_SHOP_SCORE := "shop_score"
const STEP_BUY_LOADED_DIE := "buy_loaded_die"
const STEP_BUY_EXTRA_SIX := "buy_extra_six"
const STEP_CHOOSE_SWAP_DIE := "choose_swap_die"
const STEP_CHOOSE_SWAP_FACE := "choose_swap_face"
const STEP_GO_TO_DICE_SELECT := "go_to_dice_select"
const STEP_SELECT_REQUIRED_DICE := "select_required_dice"
const STEP_COMBAT_GOOD_LUCK := "combat_good_luck"


func resolve(step_id: String, action_id: String, payload: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	match step_id:
		STEP_INTRO_WELCOME:
			if action_id == "advance_intro":
				return _accepted(STEP_INTRO_ROLL)
		STEP_INTRO_ROLL:
			if action_id == "combat_roll" and int(payload.get("roll_number", -1)) == 0:
				return _accepted(STEP_INTRO_HOLD)
		STEP_INTRO_HOLD:
			if action_id == "hold_changed":
				var held_indices := _to_int_array(payload.get("held_indices", []))
				var required := _to_int_array(context.get("required_combat_hold_indices", []))
				if _same_indices(held_indices, required):
					return _accepted(STEP_INTRO_REROLL)
		STEP_INTRO_REROLL:
			if action_id == "combat_roll" and int(payload.get("roll_number", -1)) == 1:
				return _accepted(STEP_INTRO_PAIR)
		STEP_INTRO_PAIR:
			if action_id == "advance_intro":
				return _accepted(STEP_INTRO_FINISH)
		STEP_INTRO_FINISH:
			if action_id == "combat_score":
				return _accepted(STEP_INTRO_WIN)
		STEP_INTRO_WIN:
			if action_id == "combat_next_round":
				return _accepted()
		STEP_SHOP_INTRO:
			if action_id == "advance_intro":
				return _accepted(STEP_SHOP_SCORE)
		STEP_SHOP_SCORE:
			if action_id == "advance_intro":
				return _accepted(STEP_BUY_LOADED_DIE)
		STEP_BUY_LOADED_DIE:
			if action_id == "buy_item" and payload.get("item_id", "") == "loaded_die":
				var current_loaded_die_index := int(context.get("loaded_die_index", -1))
				return _accepted(
					STEP_BUY_EXTRA_SIX, {"loaded_die_index": int(payload.get("die_index", current_loaded_die_index))}
				)
		STEP_BUY_EXTRA_SIX:
			if action_id == "open_face_item" and payload.get("item_id", "") == "extra_6":
				return _accepted(STEP_CHOOSE_SWAP_DIE, {"improved_die_index": -1})
		STEP_CHOOSE_SWAP_DIE:
			if action_id == "choose_swap_die":
				var die_color := str(payload.get("die_color", ""))
				if die_color == "colorless":
					return _accepted(STEP_CHOOSE_SWAP_FACE, {"improved_die_index": int(payload.get("die_index", -1))})
			elif action_id == "cancel_face_item":
				return _accepted(STEP_BUY_EXTRA_SIX, {"improved_die_index": -1})
		STEP_CHOOSE_SWAP_FACE:
			var improved_die_index := int(context.get("improved_die_index", -1))
			if action_id == "swap_face" and int(payload.get("die_index", -1)) == improved_die_index:
				return _accepted(STEP_GO_TO_DICE_SELECT)
			elif action_id == "back_face_item":
				return _accepted(STEP_CHOOSE_SWAP_DIE, {"improved_die_index": -1})
			elif action_id == "cancel_face_item":
				return _accepted(STEP_BUY_EXTRA_SIX, {"improved_die_index": -1})
		STEP_GO_TO_DICE_SELECT:
			if action_id == "go_to_dice_select":
				return _accepted(STEP_SELECT_REQUIRED_DICE)
		STEP_SELECT_REQUIRED_DICE:
			if action_id == "confirm_selection" and bool(context.get("selection_meets_requirements", false)):
				var selected_indices := _to_int_array(payload.get("selected_indices", []))
				return {
					"accepted": true,
					"next_step": STEP_COMBAT_GOOD_LUCK,
					"selected_indices": selected_indices,
				}
		STEP_COMBAT_GOOD_LUCK:
			if action_id == "combat_roll":
				return {"accepted": true, "complete_tutorial": true}

	return {"accepted": false}


func _accepted(next_step: String = "", updates: Dictionary = {}) -> Dictionary:
	var result := {"accepted": true}
	if not next_step.is_empty():
		result["next_step"] = next_step
	if not updates.is_empty():
		result["updates"] = updates.duplicate()
	return result


func _same_indices(left_raw: Variant, right_raw: Variant) -> bool:
	var left := _to_int_array(left_raw)
	var right := _to_int_array(right_raw)
	left.sort()
	right.sort()
	return left == right


func _to_int_array(raw: Variant) -> Array[int]:
	var result: Array[int] = []
	if raw is Array:
		for value in raw:
			result.append(int(value))
	return result
