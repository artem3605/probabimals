extends GutTest

const FLOW_PATH := "res://scripts/tutorial/tutorial_action_flow.gd"

var _flow


func before_each() -> void:
	var script := ResourceLoader.load(FLOW_PATH)
	assert_not_null(script, "TutorialActionFlow script should load")
	if script != null:
		_flow = script.new()


func test_intro_hold_advances_only_when_required_indices_match() -> void:
	var rejected: Dictionary = _flow.resolve(
		"intro_hold", "hold_changed", {"held_indices": [1]}, {"required_combat_hold_indices": [0]}
	)

	assert_false(rejected.get("accepted", false))

	var accepted: Dictionary = _flow.resolve(
		"intro_hold", "hold_changed", {"held_indices": [0]}, {"required_combat_hold_indices": [0]}
	)

	assert_true(accepted.get("accepted", false))
	assert_eq(accepted.get("next_step", ""), "intro_reroll")


func test_market_purchase_records_loaded_die_and_advances_to_face_item() -> void:
	var result: Dictionary = _flow.resolve("buy_loaded_die", "buy_item", {"item_id": "loaded_die", "die_index": 5})

	assert_true(result.get("accepted", false))
	assert_eq(result.get("next_step", ""), "buy_extra_six")
	assert_eq(result.get("updates", {}).get("loaded_die_index", -1), 5)


func test_loaded_die_purchase_keeps_existing_index_when_payload_omits_it() -> void:
	var result: Dictionary = _flow.resolve(
		"buy_loaded_die", "buy_item", {"item_id": "loaded_die"}, {"loaded_die_index": 7}
	)

	assert_true(result.get("accepted", false))
	assert_eq(result.get("updates", {}).get("loaded_die_index", -1), 7)


func test_face_swap_navigation_reports_state_updates() -> void:
	var choose_die: Dictionary = _flow.resolve(
		"choose_swap_die", "choose_swap_die", {"die_index": 0, "die_color": "colorless"}
	)

	assert_true(choose_die.get("accepted", false))
	assert_eq(choose_die.get("next_step", ""), "choose_swap_face")
	assert_eq(choose_die.get("updates", {}).get("improved_die_index", -1), 0)

	var back: Dictionary = _flow.resolve("choose_swap_face", "back_face_item")

	assert_true(back.get("accepted", false))
	assert_eq(back.get("next_step", ""), "choose_swap_die")
	assert_eq(back.get("updates", {}).get("improved_die_index", 99), -1)


func test_selection_advances_only_when_requirements_are_met() -> void:
	var rejected: Dictionary = _flow.resolve(
		"select_required_dice",
		"confirm_selection",
		{"selected_indices": [0, 1, 2, 3, 5]},
		{"selection_meets_requirements": false}
	)

	assert_false(rejected.get("accepted", false))

	var accepted: Dictionary = _flow.resolve(
		"select_required_dice",
		"confirm_selection",
		{"selected_indices": [0, 1, 2, 3, 5]},
		{"selection_meets_requirements": true}
	)

	assert_true(accepted.get("accepted", false))
	assert_eq(accepted.get("next_step", ""), "combat_good_luck")
	assert_eq_deep(accepted.get("selected_indices", []), [0, 1, 2, 3, 5])


func test_final_combat_roll_requests_tutorial_completion() -> void:
	var result: Dictionary = _flow.resolve("combat_good_luck", "combat_roll")

	assert_true(result.get("accepted", false))
	assert_true(result.get("complete_tutorial", false))
