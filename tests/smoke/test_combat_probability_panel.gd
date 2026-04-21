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


func test_combat_probability_rail_renders_and_updates_with_hold_changes() -> void:
	var scene: Dictionary = await _spawn_combat_scene(WIDE_VIEWPORT)
	var combat = scene["combat"]

	assert_not_null(combat._probability_panel)
	assert_true(combat._probability_panel.is_inside_tree())
	var panel_style: StyleBoxFlat = combat._probability_panel.get_theme_stylebox("panel")
	assert_eq(panel_style.bg_color, Color("bfeeff"))
	assert_eq(panel_style.border_width_left, 0)
	assert_eq(panel_style.border_width_top, 0)
	assert_eq(panel_style.border_width_right, 0)
	assert_eq(panel_style.border_width_bottom, 0)
	assert_false(combat.is_probability_collapsed())
	assert_true(combat.is_probability_panel_body_visible())
	assert_eq(combat.get_probability_row_count(), DataManager.get_combo_rules().size())
	assert_eq(combat.get_probability_row_name_text("pair"), "PAIR")
	assert_eq(combat.get_probability_row_name_text("small_straight"), "SMALL STRAIGHT")
	assert_eq(combat.get_probability_row_name_text("large_straight"), "LARGE STRAIGHT")
	assert_eq(combat.get_probability_row_text("pair"), "--")
	assert_eq(combat.get_probability_status_text(), "ROLL FIRST")

	var tray_x_before: float = combat.get_dice_tray_global_x()
	var tray_center_before: float = combat.get_dice_tray_center_x()
	var score_panel_center: float = combat._score_panel.global_position.x + (combat._score_panel.size.x / 2.0)
	assert_eq(tray_center_before, score_panel_center)

	combat.combat_mgr.roll_dice()
	assert_eq(combat._score_panel.scale, Vector2.ONE)
	await wait_process_frames(1)

	var open_display: Dictionary = combat.get_probability_display_snapshot()
	var combo: Dictionary = combat.combat_mgr.get_current_combo()
	var expected_highlight_indices: Array[int] = []
	var in_combo: Array = combo.get("in_combo", [])
	for i in range(in_combo.size()):
		if bool(in_combo[i]):
			expected_highlight_indices.append(i)
	assert_eq(open_display.size(), DataManager.get_combo_rules().size())
	assert_eq(combat.get_probability_row_text("pair"), "37%")
	assert_eq(combat.get_probability_status_text(), "ALL OPEN")
	assert_eq_deep(combat.get_combo_highlight_indices(), expected_highlight_indices)
	assert_eq(combat.get_dice_tray_global_x(), tray_x_before)
	assert_eq(combat.get_dice_tray_center_x(), score_panel_center)

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


func test_combat_probability_rail_does_not_shift_dice_tray_in_compact_layout() -> void:
	var scene: Dictionary = await _spawn_combat_scene(COMPACT_VIEWPORT)
	var combat = scene["combat"]
	var _root: Control = scene["root"]

	assert_false(combat.is_probability_collapsed())
	assert_true(combat.is_probability_panel_body_visible())

	var tray_x_before: float = combat.get_dice_tray_global_x()
	var score_center: float = combat._score_panel.global_position.x + (combat._score_panel.size.x / 2.0)

	combat.combat_mgr.roll_dice()
	await wait_process_frames(2)

	assert_eq(combat.get_dice_tray_global_x(), tray_x_before)
	assert_eq(combat.get_dice_tray_center_x(), score_center)


func test_hovering_dice_does_not_shift_action_buttons() -> void:
	var scene: Dictionary = await _spawn_combat_scene(WIDE_VIEWPORT)
	var combat = scene["combat"]

	var reroll_y_before: float = combat._reroll_btn.global_position.y
	var end_turn_y_before: float = combat._end_turn_btn.global_position.y

	combat._on_card_hover_enter(combat._dice_cards[0])
	await wait_process_frames(1)

	assert_eq(combat._reroll_btn.global_position.y, reroll_y_before)
	assert_eq(combat._end_turn_btn.global_position.y, end_turn_y_before)

	combat._on_card_hover_exit()
	await wait_process_frames(1)

	assert_eq(combat._reroll_btn.global_position.y, reroll_y_before)
	assert_eq(combat._end_turn_btn.global_position.y, end_turn_y_before)


func test_large_straight_row_name_has_enough_width_for_text() -> void:
	var scene: Dictionary = await _spawn_combat_scene(WIDE_VIEWPORT)
	var combat = scene["combat"]
	var large_row: PanelContainer = combat._probability_panel_ui.find_child("ProbabilityRow_large_straight", true, false)
	assert_not_null(large_row)
	if large_row == null:
		return

	var row: HBoxContainer = large_row.get_child(0)
	var name_label: Label = row.get_child(0)
	var font: Font = name_label.get_theme_font("font")
	var font_size: int = name_label.get_theme_font_size("font_size")
	var required_width: float = ceil(font.get_string_size(name_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x) + 1.0

	assert_true(name_label.custom_minimum_size.x >= required_width)


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
