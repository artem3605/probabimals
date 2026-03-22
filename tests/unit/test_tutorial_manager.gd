extends GutTest


func before_each() -> void:
	TutorialManager.completed = false
	TutorialManager.clear_active_tutorial()


func after_each() -> void:
	TutorialManager.completed = false
	TutorialManager.clear_active_tutorial()


func test_first_run_progress_tracks_required_indices_and_scripted_rolls() -> void:
	TutorialManager.start_first_run()

	assert_true(TutorialManager.is_active())
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_MARKET_INTRO)

	assert_true(TutorialManager.report_action("advance_intro"))
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_MARKET_GOAL)
	assert_true(TutorialManager.report_action("advance_intro"))
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_MARKET_SCORE)
	assert_true(TutorialManager.report_action("advance_intro"))
	assert_true(TutorialManager.report_action("buy_item", {"item_id": "loaded_die", "die_index": 5}))
	assert_true(TutorialManager.report_action("open_face_item", {"item_id": "extra_6"}))
	assert_true(TutorialManager.report_action("choose_swap_die", {"die_index": 0, "die_color": "colorless"}))
	assert_true(TutorialManager.report_action("swap_face", {"die_index": 0, "old_value": 1}))
	assert_true(TutorialManager.report_action("go_to_dice_select"))
	assert_true(TutorialManager.selection_meets_requirements([0, 1, 2, 3, 5]))
	assert_true(TutorialManager.report_action("confirm_selection", {"selected_indices": [0, 1, 2, 3, 5]}))

	assert_eq(TutorialManager.step_id, TutorialManager.STEP_COMBAT_ROLL)
	assert_true(TutorialManager.report_action("combat_roll", {"roll_number": 0}))
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_COMBAT_OPEN_COMBOS)
	assert_true(TutorialManager.report_action("combo_overlay_opened"))
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_COMBAT_EXPLAIN_COMBOS)
	assert_true(TutorialManager.report_action("advance_combos_explain"))
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_COMBAT_HOLD_PAIR)
	assert_eq_deep(TutorialManager.required_combat_hold_indices, [0, 4])
	assert_eq_deep(TutorialManager.get_scripted_roll_values(0), [6, 2, 3, 4, 6])
	assert_eq_deep(TutorialManager.get_scripted_roll_values(1), [6, 6, 6, 5, 6])


func test_completing_tutorial_marks_completion_and_clears_active_state() -> void:
	TutorialManager.start_replay()
	TutorialManager.complete_tutorial()

	assert_true(TutorialManager.completed)
	assert_false(TutorialManager.is_active())
	assert_eq(TutorialManager.step_id, "")
