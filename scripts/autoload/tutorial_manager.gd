extends Node

signal state_changed
signal step_changed(step_id: String)

const TutorialActionFlowScript = preload("res://scripts/tutorial/tutorial_action_flow.gd")

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
const STEP_COMBAT_GOOD_LUCK := "combat_good_luck"

const STEP_INTRO_WELCOME := "intro_welcome"
const STEP_INTRO_ROLL := "intro_roll"
const STEP_INTRO_HOLD := "intro_hold"
const STEP_INTRO_REROLL := "intro_reroll"
const STEP_INTRO_PAIR := "intro_pair"
const STEP_INTRO_FINISH := "intro_finish"
const STEP_INTRO_WIN := "intro_win"

const OVERLAY_STYLE := {
	"panel_width": 420.0,
	"panel_bg": Color("1a1a1a"),
	"panel_border": Color("ffd700"),
	"panel_border_width": 4,
	"panel_content_margin": 20,
	"panel_margin_left": 32.0,
	"panel_margin_right": 32.0,
	"panel_margin_top": 48.0,
	"panel_margin_bottom": 24.0,
	"panel_gap": 24.0,
	"title_font_size": 18,
	"body_font_size": 12,
	"shade_color": Color(0, 0, 0, 0.40),
	"highlight_fill": Color(0.29, 0.62, 1.0, 0.16),
	"highlight_border": Color("ffd700"),
	"highlight_padding": 8.0,
	"panel_anchor": Vector2(0.0, 1.0),
	"next_btn_size": Vector2(164, 52),
	"next_btn_font_size": 14,
	"skip_btn_size": Vector2(220, 52),
	"skip_btn_font_size": 10,
}

const STEP_TEXT := {
	"intro_welcome":
	{
		"title": "WELCOME!",
		"body":
		"In this game you will roll dice! Your goal this round: score 60 points. See the target there? Let's go!",
		"show_next": true,
		"show_skip": true,
		"skip_text": "SKIP TUTORIAL",
		"panel_width": 560,
		"panel_anchor": Vector2(0.5, 0.5),
	},
	"intro_roll":
	{
		"title": "ROLL THE DICE!",
		"body": "Press the Roll button to roll your dice!",
		"panel_width": 550,
		"panel_anchor": Vector2(0.5, 0.84),
	},
	"intro_hold":
	{
		"title": "NICE, A SIX!",
		"body": "Wow, 6 is a lot! Tap this die to hold it -- held dice won't be rerolled.",
		"panel_width": 450,
		"panel_anchor": Vector2(0.5, 0.84),
	},
	"intro_reroll":
	{
		"title": "ROLL AGAIN!",
		"body": "Now press Roll to reroll the rest!",
		"panel_width": 550,
		"panel_anchor": Vector2(0.5, 0.84),
	},
	"intro_pair":
	{
		"title": "COMBO!",
		"body":
		"Two 6s -- that's a Pair! Pairs give bonus points. The panel above lists every scoring pattern and its odds.",
		"show_next": true,
		"panel_width": 630,
		"panel_anchor": Vector2(0.5, 0.84),
	},
	"intro_finish":
	{
		"title": "TURNS",
		"body":
		"When you're out of rerolls or happy with your result, press Finish Round. One turn might not be enough, but you have several turns and their scores add up!",
		"panel_width": 630,
		"panel_anchor": Vector2(0.5, 0.84),
	},
	"intro_win":
	{
		"title": "COINS!",
		"body": "After each round you earn coins! Let's spend them on new dice and upgrades.",
		"panel_width": 630,
		"panel_anchor": Vector2(0.5, 0.95),
	},
	"market_intro":
	{
		"title": "THE FLEA MARKET",
		"body": "This is where you spend coins on new dice and upgrades.",
		"show_next": true,
		"panel_width": 650,
		"panel_anchor": Vector2(0.5, 0.75),
	},
	"market_score":
	{
		"title": "YOUR STUFF",
		"body": "Here's your coin balance and the dice in your bag. Check My Bag to see what you've got!",
		"show_next": true,
		"panel_width": 450,
		"panel_anchor": Vector2(1, 0.37),
	},
	"buy_loaded_die":
	{
		"title": "GRAB THE LOADED DIE",
		"body":
		"See the red one? It already rolls high -- lots of 5s and 6s. That means pairs and triples show up way more often. Go ahead, buy it!",
		"panel_width": 450,
		"panel_anchor": Vector2(0.5, 0.5),
	},
	"buy_extra_six":
	{
		"title": "GET EXTRA SIX",
		"body": "Nice! Now pick up Extra Six. We'll use it to soup up one of your basic dice.",
		"panel_width": 450,
		"panel_anchor": Vector2(0.7, 0.5),
	},
	"choose_swap_die":
	{
		"title": "PICK A DIE",
		"body": "Let's choose this die to upgrade!",
		"panel_width": 450,
		"panel_anchor": Vector2(0.5, 0.85),
	},
	"go_to_dice_select":
	{
		"title": "LOOKING GOOD!",
		"body": "You ran out of money! Hit Ready to go further.",
		"panel_width": 620,
		"panel_anchor": Vector2(0.5, 0.72),
	},
	"select_required_dice":
	{
		"title": "CHOOSE YOUR FIVE",
		"body":
		"Pick five dice to bring into combat. Make sure to include the red Loaded Die and the one you just upgraded!",
		"panel_width": 730,
		"panel_anchor": Vector2(0.5, 0.85),
	},
	"combat_good_luck":
	{
		"title": "GOOD LUCK!",
		"body": "We're back in combat. You already know the ropes -- roll, hold, and score your way to victory!",
		"panel_width": 550,
		"panel_anchor": Vector2(0.5, 0.84),
	},
}

const TUTORIAL_SHOP_IDS := [
	"loaded_die",
	"extra_6",
	"pair_boost",
	"basic_die",
	"balanced_die",
]

var mode: String = MODE_INACTIVE
var step_id: String = ""
var completed: bool = false
var checkpoint_scene: String = ""

var loaded_die_index: int = -1
var improved_die_index: int = -1
var selected_bag_indices: Array[int] = []
var required_combat_hold_indices: Array[int] = []
var _action_flow := TutorialActionFlowScript.new()


func is_active() -> bool:
	return mode != MODE_INACTIVE


func is_first_run() -> bool:
	return mode == MODE_FIRST_RUN


func is_replay() -> bool:
	return mode == MODE_REPLAY


func should_auto_start_on_new_game() -> bool:
	return not completed


func get_step_text(sid: String = step_id) -> Dictionary:
	return STEP_TEXT.get(sid, {})


func is_intro_step() -> bool:
	return (
		step_id
		in [
			STEP_INTRO_WELCOME,
			STEP_INTRO_ROLL,
			STEP_INTRO_HOLD,
			STEP_INTRO_REROLL,
			STEP_INTRO_PAIR,
			STEP_INTRO_FINISH,
			STEP_INTRO_WIN
		]
	)


func start_first_run() -> void:
	mode = MODE_FIRST_RUN
	_reset_active_progress()
	checkpoint_scene = SCENE_COMBAT
	required_combat_hold_indices = _to_int_array([0])
	_set_step(STEP_INTRO_WELCOME)
	_emit_state_changed()


func start_replay() -> void:
	mode = MODE_REPLAY
	_reset_active_progress()
	checkpoint_scene = SCENE_COMBAT
	required_combat_hold_indices = _to_int_array([0])
	_set_step(STEP_INTRO_WELCOME)
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
	if scene_id == SCENE_FLEA_MARKET and step_id == STEP_INTRO_WIN:
		_set_step(STEP_MARKET_INTRO)
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

	var result := _action_flow.resolve(step_id, action_id, payload, _build_action_flow_context(payload))
	if not bool(result.get("accepted", false)):
		return false

	_apply_action_flow_result(result)
	return true


func _build_action_flow_context(payload: Dictionary) -> Dictionary:
	var selected_indices := _to_int_array(payload.get("selected_indices", []))
	return {
		"required_combat_hold_indices": required_combat_hold_indices.duplicate(),
		"loaded_die_index": loaded_die_index,
		"improved_die_index": improved_die_index,
		"selection_meets_requirements": selection_meets_requirements(selected_indices),
	}


func _apply_action_flow_result(result: Dictionary) -> void:
	var updates: Dictionary = result.get("updates", {})
	if updates.has("loaded_die_index"):
		loaded_die_index = int(updates["loaded_die_index"])
	if updates.has("improved_die_index"):
		improved_die_index = int(updates["improved_die_index"])

	if result.has("selected_indices"):
		set_selected_bag_indices(_to_int_array(result["selected_indices"]))

	if bool(result.get("complete_tutorial", false)):
		complete_tutorial()
		return

	var next_step := str(result.get("next_step", ""))
	if not next_step.is_empty():
		_set_step(next_step)


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
		STEP_MARKET_INTRO, STEP_MARKET_SCORE:
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
	if step_id == STEP_CHOOSE_SWAP_DIE:
		return die_index == 0 and die.color == "colorless"
	return true


func is_swap_face_allowed(die_index: int, face: DiceFace) -> bool:
	if not is_active():
		return true
	if step_id == STEP_CHOOSE_SWAP_FACE:
		return die_index == improved_die_index and face.value <= 3
	return true


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
	if step_id == STEP_INTRO_ROLL:
		return _to_int_array([6, 3, 2, 5, 1])
	if step_id == STEP_INTRO_REROLL:
		return _to_int_array([6, 6, 1, 3, 5])
	return []


func should_use_scripted_rolls() -> bool:
	if not is_active() or checkpoint_scene != SCENE_COMBAT:
		return false
	return is_intro_step()


func is_combat_roll_allowed() -> bool:
	if not is_active():
		return true
	if step_id == STEP_INTRO_WIN:
		return true
	return step_id in [STEP_INTRO_ROLL, STEP_INTRO_REROLL, STEP_COMBAT_GOOD_LUCK]


func should_restore_combo_overlay() -> bool:
	return false


func is_combat_hold_allowed(die_index: int, held_indices: Array[int]) -> bool:
	if not is_active():
		return true
	if step_id == STEP_INTRO_WIN:
		return true
	if step_id != STEP_INTRO_HOLD:
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
	return step_id in [STEP_INTRO_FINISH, STEP_INTRO_WIN]


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
