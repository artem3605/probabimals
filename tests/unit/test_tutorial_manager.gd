extends GutTest


func before_each() -> void:
	TutorialManager.completed = false
	TutorialManager.clear_active_tutorial()


func after_each() -> void:
	TutorialManager.completed = false
	TutorialManager.clear_active_tutorial()


func test_combat_tutorial_prompts_are_anchored_below_dice() -> void:
	var combat_prompt_steps := [
		TutorialManager.STEP_INTRO_ROLL,
		TutorialManager.STEP_INTRO_HOLD,
		TutorialManager.STEP_INTRO_REROLL,
		TutorialManager.STEP_INTRO_PAIR,
		TutorialManager.STEP_INTRO_FINISH,
		TutorialManager.STEP_COMBAT_GOOD_LUCK,
	]

	for step_id in combat_prompt_steps:
		var config: Dictionary = TutorialManager.STEP_TEXT[step_id]
		var anchor: Vector2 = config.get("panel_anchor", Vector2.ZERO)
		assert_true(anchor.y >= 0.82, "%s should render below the dice row" % step_id)


func test_fixed_tutorial_shop_uses_current_shop_size() -> void:
	var offerings := TutorialManager.get_fixed_shop_offerings()

	assert_eq(offerings.size(), 5)
	assert_ne(_find_item_index(offerings, "loaded_die"), -1)
	assert_ne(_find_item_index(offerings, "extra_6"), -1)


func test_extra_six_prompt_is_shifted_right_in_shop_tutorial() -> void:
	var config: Dictionary = TutorialManager.STEP_TEXT[TutorialManager.STEP_BUY_EXTRA_SIX]
	var anchor: Vector2 = config.get("panel_anchor", Vector2.ZERO)

	assert_gt(anchor.x, 0.5)


func test_first_run_progress_tracks_required_indices_and_scripted_rolls() -> void:
	TutorialManager.start_first_run()

	assert_true(TutorialManager.is_active())
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_INTRO_WELCOME)
	assert_eq(TutorialManager.checkpoint_scene, TutorialManager.SCENE_COMBAT)
	assert_eq_deep(TutorialManager.required_combat_hold_indices, [0])

	assert_true(TutorialManager.report_action("advance_intro"))
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_INTRO_ROLL)
	assert_eq_deep(TutorialManager.get_scripted_roll_values(0), [6, 3, 2, 5, 1])
	assert_true(TutorialManager.report_action("combat_roll", {"roll_number": 0}))
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_INTRO_HOLD)
	assert_true(TutorialManager.report_action("hold_changed", {"held_indices": [0]}))
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_INTRO_REROLL)
	assert_eq_deep(TutorialManager.get_scripted_roll_values(1), [6, 6, 1, 3, 5])
	assert_true(TutorialManager.report_action("combat_roll", {"roll_number": 1}))
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_INTRO_PAIR)
	assert_true(TutorialManager.report_action("advance_intro"))
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_INTRO_FINISH)
	assert_true(TutorialManager.report_action("combat_score"))
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_INTRO_WIN)
	TutorialManager.enter_scene(TutorialManager.SCENE_FLEA_MARKET)
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_MARKET_INTRO)
	assert_true(TutorialManager.report_action("advance_intro"))
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_MARKET_SCORE)
	assert_true(TutorialManager.report_action("advance_intro"))
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_BUY_LOADED_DIE)
	assert_true(TutorialManager.report_action("buy_item", {"item_id": "loaded_die", "die_index": 5}))
	assert_eq(TutorialManager.loaded_die_index, 5)
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_BUY_EXTRA_SIX)
	assert_true(TutorialManager.report_action("open_face_item", {"item_id": "extra_6"}))
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_CHOOSE_SWAP_DIE)
	assert_true(TutorialManager.report_action("choose_swap_die", {"die_index": 0, "die_color": "colorless"}))
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_CHOOSE_SWAP_FACE)
	assert_eq(TutorialManager.improved_die_index, 0)
	assert_true(TutorialManager.report_action("swap_face", {"die_index": 0, "old_value": 1}))
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_GO_TO_DICE_SELECT)
	assert_true(TutorialManager.report_action("go_to_dice_select"))
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_SELECT_REQUIRED_DICE)
	assert_true(TutorialManager.selection_meets_requirements([0, 1, 2, 3, 5]))
	assert_true(TutorialManager.report_action("confirm_selection", {"selected_indices": [0, 1, 2, 3, 5]}))
	assert_eq_deep(TutorialManager.required_combat_hold_indices, [0, 4])

	assert_eq(TutorialManager.step_id, TutorialManager.STEP_COMBAT_GOOD_LUCK)
	assert_true(TutorialManager.report_action("combat_roll", {"roll_number": 0}))
	assert_true(TutorialManager.completed)
	assert_false(TutorialManager.is_active())


func _find_item_index(items: Array, item_id: String) -> int:
	for i in range(items.size()):
		if items[i].get("id", "") == item_id:
			return i
	return -1


func test_face_swap_step_only_advances_after_successful_swap_commit() -> void:
	TutorialManager.start_first_run()
	TutorialManager.report_action("advance_intro")
	TutorialManager.report_action("combat_roll", {"roll_number": 0})
	TutorialManager.report_action("hold_changed", {"held_indices": [0]})
	TutorialManager.report_action("combat_roll", {"roll_number": 1})
	TutorialManager.report_action("advance_intro")
	TutorialManager.report_action("combat_score")
	TutorialManager.enter_scene(TutorialManager.SCENE_FLEA_MARKET)
	TutorialManager.report_action("advance_intro")
	TutorialManager.report_action("advance_intro")
	TutorialManager.report_action("buy_item", {"item_id": "loaded_die", "die_index": 5})

	assert_eq(TutorialManager.step_id, TutorialManager.STEP_BUY_EXTRA_SIX)
	assert_true(TutorialManager.report_action("open_face_item", {"item_id": "extra_6"}))
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_CHOOSE_SWAP_DIE)
	assert_true(TutorialManager.report_action("cancel_face_item"))
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_BUY_EXTRA_SIX)
	assert_eq(TutorialManager.improved_die_index, -1)

	assert_true(TutorialManager.report_action("open_face_item", {"item_id": "extra_6"}))
	assert_true(TutorialManager.report_action("choose_swap_die", {"die_index": 0, "die_color": "colorless"}))
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_CHOOSE_SWAP_FACE)
	assert_true(TutorialManager.report_action("back_face_item"))
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_CHOOSE_SWAP_DIE)
	assert_eq(TutorialManager.improved_die_index, -1)

	assert_true(TutorialManager.report_action("choose_swap_die", {"die_index": 0, "die_color": "colorless"}))
	assert_true(TutorialManager.report_action("swap_face", {"die_index": 0, "old_value": 1}))
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_GO_TO_DICE_SELECT)
	assert_eq(TutorialManager.improved_die_index, 0)


func test_completing_tutorial_marks_completion_and_clears_active_state() -> void:
	TutorialManager.start_replay()
	TutorialManager.complete_tutorial()

	assert_true(TutorialManager.completed)
	assert_false(TutorialManager.is_active())
	assert_eq(TutorialManager.step_id, "")
