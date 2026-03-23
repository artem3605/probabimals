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
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_MARKET_SCORE)
	assert_true(TutorialManager.report_action("advance_intro"))
	assert_true(TutorialManager.report_action("buy_item", {"item_id": "loaded_die", "die_index": 5}))
	assert_true(TutorialManager.report_action("open_face_item", {"item_id": "extra_6"}))
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_GO_TO_DICE_SELECT)
	TutorialManager.improved_die_index = 0
	assert_true(TutorialManager.report_action("go_to_dice_select"))
	assert_true(TutorialManager.selection_meets_requirements([0, 1, 2, 3, 5]))
	assert_true(TutorialManager.report_action("confirm_selection", {"selected_indices": [0, 1, 2, 3, 5]}))

	assert_eq(TutorialManager.step_id, TutorialManager.STEP_COMBAT_GOOD_LUCK)
	assert_true(TutorialManager.report_action("combat_roll", {"roll_number": 0}))
	assert_true(TutorialManager.completed)
	assert_false(TutorialManager.is_active())


func test_completing_tutorial_marks_completion_and_clears_active_state() -> void:
	TutorialManager.start_replay()
	TutorialManager.complete_tutorial()

	assert_true(TutorialManager.completed)
	assert_false(TutorialManager.is_active())
	assert_eq(TutorialManager.step_id, "")
