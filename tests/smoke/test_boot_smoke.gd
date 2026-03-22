extends GutTest

const TestData = preload("res://tests/support/test_data.gd")

func test_autoloads_boot_with_game_data_loaded() -> void:
	assert_not_null(DataManager)
	assert_not_null(GameManager)
	assert_not_null(AudioManager)
	assert_not_null(TutorialManager)
	assert_true(DataManager.get_combo_rules().size() > 0)
	assert_true(DataManager.get_all_faces().size() > 0)

func test_seeded_combat_flow_runs_headless() -> void:
	var manager: CombatManager = CombatManager.new()
	autoqfree(manager)
	var dice: Array[Die] = [
		TestData.deterministic_die([2]),
		TestData.deterministic_die([3]),
		TestData.deterministic_die([4]),
		TestData.deterministic_die([5]),
		TestData.deterministic_die([6]),
	]

	watch_signals(manager)
	manager.start_combat(dice, 100, 1, 1, TestData.load_combo_rules(), 1)
	manager.roll_dice()
	var result: Dictionary = manager.score_hand([])

	assert_eq(result["combo"]["type"], "large_straight")
	assert_eq(result["score_data"]["total"], 100)
	assert_signal_emitted_with_parameters(manager, "combat_ended", [100, true])
