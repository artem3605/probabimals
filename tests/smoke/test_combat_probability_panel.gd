extends GutTest

const TestData = preload("res://tests/support/test_data.gd")
const COMBAT_SCENE := preload("res://scenes/combat/combat_screen.tscn")
const WIDE_VIEWPORT := Vector2(1440, 720)
const COMPACT_VIEWPORT := Vector2(1024, 720)


func before_each() -> void:
	GameManager.dice_bag = DiceBag.new()
	for _i in range(5):
		GameManager.dice_bag.add_die(Die.new())
	GameManager.current_round = 1
	GameManager.target_score = 150
	GameManager.hands_per_round = 2
	GameManager.rerolls_per_hand = 2
	GameManager.coins = 50
	GameManager.modifiers.clear()
	GameManager.selected_dice = [
		TestData.deterministic_die([2, 6]),
		TestData.deterministic_die([2, 6]),
		TestData.deterministic_die([3, 6]),
		TestData.deterministic_die([4, 6]),
		TestData.deterministic_die([6, 6]),
	]
	TutorialManager.completed = false
	TutorialManager.clear_active_tutorial()


func after_each() -> void:
	GameManager.selected_dice.clear()
	TutorialManager.completed = false
	TutorialManager.clear_active_tutorial()


func test_combat_probability_panel_renders_and_updates_with_hold_changes_in_wide_layout() -> void:
	var scene: Dictionary = await _spawn_combat_scene(WIDE_VIEWPORT)
	var combat = scene["combat"]

	assert_not_null(combat._probability_panel)
	assert_true(combat._probability_panel.custom_minimum_size.x < combat._score_panel.custom_minimum_size.x)
	assert_eq(combat._probability_dock.get_parent(), combat)
	assert_true(combat.is_probability_collapsed())
	assert_eq(combat.get_probability_row_count(), DataManager.get_combo_rules().size())
	assert_eq(combat.get_probability_row_name_text("pair"), "PAIR")
	assert_eq(combat.get_probability_row_name_text("small_straight"), "SMALL STRAIGHT")
	assert_eq(combat.get_probability_row_name_text("large_straight"), "LARGE STRAIGHT")
	assert_eq(combat.get_probability_row_text("pair"), "--")
	assert_eq(combat.get_probability_status_text(), "ROLL FIRST")
	var tray_x_before_toggle: float = combat.get_dice_tray_global_x()
	var tray_center_before_toggle: float = combat.get_dice_tray_center_x()
	var score_panel_center: float = combat._score_panel.global_position.x + (combat._score_panel.size.x / 2.0)
	assert_eq(tray_center_before_toggle, score_panel_center)

	combat.combat_mgr.roll_dice()
	await wait_process_frames(1)

	var open_display: Dictionary = combat.get_probability_display_snapshot()
	assert_eq(open_display.size(), DataManager.get_combo_rules().size())
	assert_eq(combat.get_probability_row_text("pair"), "37.0%")
	assert_eq(combat.get_probability_status_text(), "ALL OPEN")
	assert_eq(combat.get_dice_tray_global_x(), tray_x_before_toggle)
	assert_eq(combat.get_dice_tray_center_x(), score_panel_center)

	combat.toggle_probability_panel()
	await wait_process_frames(1)

	assert_false(combat.is_probability_collapsed())
	assert_true(combat.is_probability_panel_body_visible())
	assert_eq(combat.get_dice_tray_global_x(), tray_x_before_toggle)
	assert_eq(combat.get_dice_tray_center_x(), score_panel_center)

	combat.toggle_probability_panel()
	await wait_process_frames(1)

	assert_true(combat.is_probability_collapsed())
	assert_false(combat.is_probability_panel_body_visible())
	assert_eq_deep(combat.get_probability_display_snapshot(), open_display)
	assert_eq(combat.get_dice_tray_global_x(), tray_x_before_toggle)
	assert_eq(combat.get_dice_tray_center_x(), score_panel_center)

	combat.toggle_probability_panel()
	await wait_process_frames(1)

	assert_false(combat.is_probability_collapsed())
	assert_true(combat.is_probability_panel_body_visible())

	combat.combat_mgr.hold_die(0)
	combat.combat_mgr.hold_die(1)
	await wait_process_frames(1)

	var held_display: Dictionary = combat.get_probability_display_snapshot()
	assert_eq(held_display.size(), DataManager.get_combo_rules().size())
	assert_ne(held_display, open_display)
	assert_eq(combat.get_probability_status_text(), "2 LOCKED")

	combat.combat_mgr.unhold_die(0)
	combat.combat_mgr.unhold_die(1)
	await wait_process_frames(1)

	assert_eq_deep(combat.get_probability_display_snapshot(), open_display)
	assert_eq(combat.get_probability_status_text(), "ALL OPEN")


func test_combat_probability_panel_overlay_does_not_shift_dice() -> void:
	var scene: Dictionary = await _spawn_combat_scene(COMPACT_VIEWPORT)
	var combat = scene["combat"]
	var root: Control = scene["root"]
	var viewport_width: float = root.size.x

	assert_true(combat.is_probability_collapsed())
	assert_false(combat.is_probability_panel_body_visible())
	assert_lte(combat.get_combo_button_right_x(), viewport_width)
	assert_lte(combat.get_probability_toggle_right_x(), viewport_width)

	var tray_x_before: float = combat.get_dice_tray_global_x()

	combat.toggle_probability_panel()
	await wait_process_frames(2)

	assert_false(combat.is_probability_collapsed())
	assert_true(combat.is_probability_panel_body_visible())
	assert_eq(combat.get_dice_tray_global_x(), tray_x_before)
	assert_lte(combat.get_combo_button_right_x(), viewport_width)
	assert_lte(combat.get_probability_toggle_right_x(), viewport_width)


func _spawn_combat_scene(view_size: Vector2) -> Dictionary:
	var root := Control.new()
	root.size = view_size
	add_child_autofree(root)

	var combat = COMBAT_SCENE.instantiate()
	autoqfree(combat)
	root.add_child(combat)
	await wait_process_frames(3)

	return {
		"root": root,
		"combat": combat,
	}
