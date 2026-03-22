extends Node

signal state_changed
signal step_changed(step_id: String)

const MODE_INACTIVE := "inactive"
const MODE_FIRST_RUN := "first_run"
const MODE_REPLAY := "replay"

const SCENE_FLEA_MARKET := "flea_market"
const SCENE_DICE_SELECT := "dice_select"
const SCENE_COMBAT := "combat"

const STEP_MARKET_INTRO := "market_intro"
const STEP_MARKET_GOAL := "market_goal"
const STEP_MARKET_SCORE := "market_score"
const STEP_BUY_LOADED_DIE := "buy_loaded_die"
const STEP_BUY_EXTRA_SIX := "buy_extra_six"
const STEP_CHOOSE_SWAP_DIE := "choose_swap_die"
const STEP_CHOOSE_SWAP_FACE := "choose_swap_face"
const STEP_GO_TO_DICE_SELECT := "go_to_dice_select"
const STEP_SELECT_REQUIRED_DICE := "select_required_dice"
const STEP_COMBAT_ROLL := "combat_roll"
const STEP_COMBAT_OPEN_COMBOS := "combat_open_combos"
const STEP_COMBAT_EXPLAIN_COMBOS := "combat_explain_combos"
const STEP_COMBAT_HOLD_PAIR := "combat_hold_pair"
const STEP_COMBAT_REROLL := "combat_reroll"
const STEP_COMBAT_SCORE := "combat_score"
const STEP_COMBAT_WIN := "combat_win"

const TUTORIAL_SHOP_IDS := [
	"loaded_die",
	"extra_6",
	"pair_boost",
	"basic_die",
	"extra_5",
	"balanced_die",
	"reroll_plus",
]

var mode: String = MODE_INACTIVE
var step_id: String = ""
var completed: bool = false
var checkpoint_scene: String = ""

var loaded_die_index: int = -1
var improved_die_index: int = -1
var selected_bag_indices: Array[int] = []
var required_combat_hold_indices: Array[int] = []


func is_active() -> bool:
	return mode != MODE_INACTIVE


func is_first_run() -> bool:
	return mode == MODE_FIRST_RUN


func is_replay() -> bool:
	return mode == MODE_REPLAY


func should_auto_start_on_new_game() -> bool:
	return not completed


func start_first_run() -> void:
	mode = MODE_FIRST_RUN
	_reset_active_progress()
	checkpoint_scene = SCENE_FLEA_MARKET
	_set_step(STEP_MARKET_INTRO)
	_emit_state_changed()


func start_replay() -> void:
	mode = MODE_REPLAY
	_reset_active_progress()
	checkpoint_scene = SCENE_FLEA_MARKET
	_set_step(STEP_MARKET_INTRO)
	_emit_state_changed()


func restart_current_tutorial() -> void:
	if is_replay():
		start_replay()
	else:
		start_first_run()


func complete_tutorial() -> void:
	completed = true
	_clear_active_progress()
	_emit_state_changed()


func clear_active_tutorial() -> void:
	_clear_active_progress()
	_emit_state_changed()


func enter_scene(scene_id: String) -> void:
	if not is_active():
		return
	checkpoint_scene = scene_id
	_emit_state_changed()


func build_save_data() -> Dictionary:
	return {
		"mode": mode,
		"step_id": step_id,
		"completed": completed,
		"checkpoint_scene": checkpoint_scene,
		"loaded_die_index": loaded_die_index,
		"improved_die_index": improved_die_index,
		"selected_bag_indices": selected_bag_indices.duplicate(),
		"required_combat_hold_indices": required_combat_hold_indices.duplicate(),
	}


func apply_save_data(data: Dictionary) -> void:
	completed = bool(data.get("completed", false))
	mode = str(data.get("mode", MODE_INACTIVE))
	step_id = str(data.get("step_id", ""))
	checkpoint_scene = str(data.get("checkpoint_scene", ""))
	loaded_die_index = int(data.get("loaded_die_index", -1))
	improved_die_index = int(data.get("improved_die_index", -1))
	selected_bag_indices = _to_int_array(data.get("selected_bag_indices", []))
	required_combat_hold_indices = _to_int_array(data.get("required_combat_hold_indices", []))
	_emit_state_changed()
	step_changed.emit(step_id)


func report_action(action_id: String, payload: Dictionary = {}) -> bool:
	if not is_active():
		return false

	match step_id:
		STEP_MARKET_INTRO:
			if action_id == "advance_intro":
				_set_step(STEP_MARKET_GOAL)
				return true
		STEP_MARKET_GOAL:
			if action_id == "advance_intro":
				_set_step(STEP_MARKET_SCORE)
				return true
		STEP_MARKET_SCORE:
			if action_id == "advance_intro":
				_set_step(STEP_BUY_LOADED_DIE)
				return true
		STEP_BUY_LOADED_DIE:
			if action_id == "buy_item" and payload.get("item_id", "") == "loaded_die":
				loaded_die_index = int(payload.get("die_index", loaded_die_index))
				_set_step(STEP_BUY_EXTRA_SIX)
				return true
		STEP_BUY_EXTRA_SIX:
			if action_id == "open_face_item" and payload.get("item_id", "") == "extra_6":
				_set_step(STEP_CHOOSE_SWAP_DIE)
				return true
		STEP_CHOOSE_SWAP_DIE:
			if action_id == "choose_swap_die":
				var die_color := str(payload.get("die_color", ""))
				if die_color == "colorless":
					improved_die_index = int(payload.get("die_index", -1))
					_set_step(STEP_CHOOSE_SWAP_FACE)
					return true
		STEP_CHOOSE_SWAP_FACE:
			if action_id == "swap_face" and int(payload.get("die_index", -1)) == improved_die_index:
				if int(payload.get("old_value", 0)) <= 3:
					_set_step(STEP_GO_TO_DICE_SELECT)
					return true
		STEP_GO_TO_DICE_SELECT:
			if action_id == "go_to_dice_select":
				_set_step(STEP_SELECT_REQUIRED_DICE)
				return true
		STEP_SELECT_REQUIRED_DICE:
			if action_id == "confirm_selection":
				var indices := _to_int_array(payload.get("selected_indices", []))
				if selection_meets_requirements(indices):
					set_selected_bag_indices(indices)
					_set_step(STEP_COMBAT_ROLL)
					return true
		STEP_COMBAT_ROLL:
			if action_id == "combat_roll" and int(payload.get("roll_number", -1)) == 0:
				_set_step(STEP_COMBAT_OPEN_COMBOS)
				return true
		STEP_COMBAT_OPEN_COMBOS:
			if action_id == "combo_overlay_opened":
				_set_step(STEP_COMBAT_EXPLAIN_COMBOS)
				return true
		STEP_COMBAT_EXPLAIN_COMBOS:
			if action_id == "advance_combos_explain":
				_set_step(STEP_COMBAT_HOLD_PAIR)
				return true
		STEP_COMBAT_HOLD_PAIR:
			if action_id == "hold_changed":
				var held_indices := _to_int_array(payload.get("held_indices", []))
				held_indices.sort()
				var required := required_combat_hold_indices.duplicate()
				required.sort()
				if held_indices == required:
					_set_step(STEP_COMBAT_REROLL)
					return true
		STEP_COMBAT_REROLL:
			if action_id == "combat_roll" and int(payload.get("roll_number", -1)) == 1:
				_set_step(STEP_COMBAT_SCORE)
				return true
		STEP_COMBAT_SCORE:
			if action_id == "combat_win":
				_set_step(STEP_COMBAT_WIN)
				return true
		STEP_COMBAT_WIN:
			if action_id == "combat_next_round":
				complete_tutorial()
				return true

	return false


func get_fixed_shop_offerings() -> Array[Dictionary]:
	var offerings: Array[Dictionary] = []
	var catalogue := DataManager.get_shop_catalogue()
	for item_id in TUTORIAL_SHOP_IDS:
		for item in catalogue:
			if item is Dictionary and item.get("id", "") == item_id:
				offerings.append(item.duplicate(true))
				break
	return offerings


func is_shop_item_allowed(item_id: String) -> bool:
	if not is_active():
		return true
	match step_id:
		STEP_MARKET_INTRO, STEP_MARKET_GOAL, STEP_MARKET_SCORE:
			return false
		STEP_BUY_LOADED_DIE:
			return item_id == "loaded_die"
		STEP_BUY_EXTRA_SIX:
			return item_id == "extra_6"
		_:
			return false


func can_refresh_market() -> bool:
	return not is_active()


func can_go_to_dice_select() -> bool:
	return not is_active() or step_id == STEP_GO_TO_DICE_SELECT


func is_swap_die_allowed(die: Die, die_index: int) -> bool:
	if not is_active():
		return true
	if step_id != STEP_CHOOSE_SWAP_DIE:
		return false
	return die_index >= 0 and die.color == "colorless"


func is_swap_face_allowed(die_index: int, face: DiceFace) -> bool:
	if not is_active():
		return true
	if step_id != STEP_CHOOSE_SWAP_FACE:
		return false
	return die_index == improved_die_index and face.value <= 3


func selection_meets_requirements(selected_indices: Array[int]) -> bool:
	if not is_active():
		return selected_indices.size() == 5
	if selected_indices.size() != 5:
		return false
	return selected_indices.has(loaded_die_index) and selected_indices.has(improved_die_index)


func set_selected_bag_indices(indices: Array[int]) -> void:
	selected_bag_indices = indices.duplicate()
	required_combat_hold_indices.clear()
	for i in range(selected_bag_indices.size()):
		var bag_index := selected_bag_indices[i]
		if bag_index == loaded_die_index or bag_index == improved_die_index:
			required_combat_hold_indices.append(i)
	required_combat_hold_indices.sort()
	_emit_state_changed()


func get_scripted_roll_values(roll_number: int) -> Array[int]:
	var result := _to_int_array([1, 1, 1, 1, 1])
	if selected_bag_indices.size() != 5:
		return result

	var filler := _to_int_array([2, 3, 4] if roll_number == 0 else [6, 6, 5])
	var filler_index := 0
	for i in range(5):
		if required_combat_hold_indices.has(i):
			result[i] = 6
		else:
			result[i] = filler[filler_index]
			filler_index += 1
	return result


func should_use_scripted_rolls() -> bool:
	return is_active() and checkpoint_scene == SCENE_COMBAT


func is_combat_roll_allowed() -> bool:
	if not is_active():
		return true
	return step_id == STEP_COMBAT_ROLL or step_id == STEP_COMBAT_REROLL


func should_restore_combo_overlay() -> bool:
	return is_active() and checkpoint_scene == SCENE_COMBAT and step_id == STEP_COMBAT_EXPLAIN_COMBOS


func is_combat_hold_allowed(die_index: int, held_indices: Array[int]) -> bool:
	if not is_active():
		return true
	if step_id != STEP_COMBAT_HOLD_PAIR:
		return false
	if held_indices.size() > required_combat_hold_indices.size():
		return false
	if not required_combat_hold_indices.has(die_index):
		return false
	for held_index in held_indices:
		if not required_combat_hold_indices.has(held_index):
			return false
	return true


func is_combat_score_allowed() -> bool:
	if not is_active():
		return true
	return step_id == STEP_COMBAT_SCORE


func get_required_bag_indices() -> Array[int]:
	var indices: Array[int] = []
	if loaded_die_index >= 0:
		indices.append(loaded_die_index)
	if improved_die_index >= 0:
		indices.append(improved_die_index)
	return indices


func _reset_active_progress() -> void:
	loaded_die_index = -1
	improved_die_index = -1
	selected_bag_indices.clear()
	required_combat_hold_indices.clear()


func _clear_active_progress() -> void:
	mode = MODE_INACTIVE
	step_id = ""
	checkpoint_scene = ""
	_reset_active_progress()


func _set_step(new_step_id: String) -> void:
	step_id = new_step_id
	_emit_state_changed()
	step_changed.emit(step_id)


func _emit_state_changed() -> void:
	state_changed.emit()


func _to_int_array(raw: Variant) -> Array[int]:
	var result: Array[int] = []
	if raw is Array:
		for value in raw:
			result.append(int(value))
	return result
