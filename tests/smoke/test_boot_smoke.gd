extends GutTest

const TestData = preload("res://tests/support/test_data.gd")
const MAIN_MENU_SCENE := preload("res://scenes/main_menu/main_menu.tscn")


func after_each() -> void:
	GameManager.last_run_result = {}


func test_autoloads_boot_with_game_data_loaded() -> void:
	assert_not_null(DataManager)
	assert_not_null(GameManager)
	assert_not_null(AudioManager)
	assert_not_null(TutorialManager)
	assert_true(DataManager.get_combo_rules().size() > 0)
	assert_true(DataManager.get_all_faces().size() > 0)
	var configured_version := str(ProjectSettings.get_setting("application/config/version", ""))
	assert_false(configured_version.is_empty())
	assert_eq(GameManager.get_app_version(), configured_version)


func test_main_menu_scene_instantiates_with_playtest_button() -> void:
	assert_not_null(MAIN_MENU_SCENE)

	var menu: Control = add_child_autoqfree(MAIN_MENU_SCENE.instantiate())

	assert_not_null(menu.get_node("ButtonContainer/PlaytestSurveyButton"))


func test_main_menu_shows_last_run_result_overlay_and_continue_clears() -> void:
	GameManager.last_run_result = {"victory": true, "round": 3, "total_score": 420, "coins": 17}
	assert_not_null(MAIN_MENU_SCENE)

	var menu: Control = add_child_autoqfree(MAIN_MENU_SCENE.instantiate())
	await wait_process_frames(1)

	var overlay: Control = menu.find_child("RunResultOverlay", true, false) as Control
	assert_not_null(overlay)
	assert_true(_has_label_text(overlay, "VICTORY"))
	assert_true(_has_label_text(overlay, "ROUND 3"))
	assert_true(_has_label_text(overlay, "SCORE 420"))
	assert_true(_has_label_text(overlay, "COINS 17"))

	var continue_btn: Button = menu.find_child("RunResultContinueButton", true, false) as Button
	assert_not_null(continue_btn)
	if continue_btn == null:
		return

	continue_btn.pressed.emit()
	await wait_process_frames(1)

	assert_eq_deep(GameManager.last_run_result, {})
	assert_true(not is_instance_valid(overlay) or not overlay.visible)


func test_main_menu_shows_defeat_run_result_overlay() -> void:
	GameManager.last_run_result = {"victory": false, "round": 3, "total_score": 12, "coins": 4}
	assert_not_null(MAIN_MENU_SCENE)

	var menu: Control = add_child_autoqfree(MAIN_MENU_SCENE.instantiate())
	await wait_process_frames(1)

	var overlay: Control = menu.find_child("RunResultOverlay", true, false) as Control
	assert_not_null(overlay)
	assert_true(_has_label_text(overlay, "DEFEAT"))
	assert_true(_has_label_text(overlay, "ROUND 3"))
	assert_true(_has_label_text(overlay, "SCORE 12"))
	assert_true(_has_label_text(overlay, "COINS 4"))


func test_combat_screen_script_loads() -> void:
	assert_not_null(load("res://scenes/combat/combat_screen.gd"))


func test_combo_reveal_fx_layer_has_visual_only_api() -> void:
	var script: Script = load("res://scripts/ui/combo_reveal_fx.gd")
	assert_not_null(script)

	var fx: Control = script.new()
	autoqfree(fx)
	add_child_autofree(fx)

	assert_eq(fx.mouse_filter, Control.MOUSE_FILTER_IGNORE)

	var combo := {
		"name": "Pair",
		"type": "pair",
		"priority": 1,
		"in_combo": [true, true, false, false, false],
	}
	fx.play(combo, [], Color("ff6b4a"))

	assert_eq(fx.get_reveal_tier(), 1)
	assert_eq(fx.get_active_combo_type(), "pair")


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
	var result: Dictionary = manager.score_hand([] as Array[Modifier])

	assert_eq(result["combo"]["type"], "large_straight")
	assert_eq(result["score_data"]["total"], 160)
	assert_signal_emitted_with_parameters(manager, "combat_ended", [160, true])


func _has_label_text(root: Node, expected: String) -> bool:
	if root == null:
		return false
	if root is Label and (root as Label).text == expected:
		return true
	for child in root.get_children():
		if _has_label_text(child, expected):
			return true
	return false
