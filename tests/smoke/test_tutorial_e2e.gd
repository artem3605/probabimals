extends GutTest

const FLEA_MARKET_SCENE := preload("res://scenes/flea_market/flea_market_screen.tscn")
const DICE_SELECT_SCENE := preload("res://scenes/dice_select/dice_select_screen.tscn")
const COMBAT_SCENE := preload("res://scenes/combat/combat_screen.tscn")
const ItemCard = preload("res://scripts/ui/item_card.gd")


func before_each() -> void:
	GameManager.dice_bag = DiceBag.new()
	for _i in range(5):
		GameManager.dice_bag.add_die(Die.new())
	GameManager.selected_dice.clear()
	GameManager.current_round = 1
	GameManager.target_score = 150
	GameManager.hands_per_round = 4
	GameManager.rerolls_per_hand = 3
	GameManager.coins = 50
	GameManager.modifiers.clear()
	TutorialManager.completed = false
	TutorialManager.clear_active_tutorial()


func after_each() -> void:
	TutorialManager.completed = false
	TutorialManager.clear_active_tutorial()


func test_tutorial_flow_reaches_completion_end_to_end() -> void:
	TutorialManager.start_first_run()

	var flea_market = FLEA_MARKET_SCENE.instantiate()
	autoqfree(flea_market)
	add_child_autofree(flea_market)
	await wait_process_frames(3)

	flea_market._tutorial_overlay._next_btn.emit_signal("pressed")
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_MARKET_GOAL)
	flea_market._tutorial_overlay._next_btn.emit_signal("pressed")
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_MARKET_SCORE)
	flea_market._tutorial_overlay._next_btn.emit_signal("pressed")
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_BUY_LOADED_DIE)
	var loaded_index := _find_shop_index(flea_market._shop_offerings, "loaded_die")
	var loaded_card = flea_market._shop_cards[loaded_index]
	assert_false(loaded_card.buy_button.disabled)
	assert_eq(loaded_card.buy_button.text, "BUY THIS")

	loaded_card.buy_button.emit_signal("pressed")
	await wait_process_frames(2)
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_BUY_EXTRA_SIX)
	var extra_six_index := _find_shop_index(flea_market._shop_offerings, "extra_6")
	var extra_six_card = flea_market._shop_cards[extra_six_index]
	assert_false(extra_six_card.buy_button.disabled)
	assert_eq(extra_six_card.buy_button.text, "BUY THIS")

	extra_six_card.buy_button.emit_signal("pressed")
	await wait_process_frames(2)
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_CHOOSE_SWAP_DIE)

	flea_market._on_swap_die_selected(0)
	await wait_process_frames(2)
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_CHOOSE_SWAP_FACE)

	var replace_face_index := GameManager.dice_bag.get_die(0).get_face_values().find(1)
	if replace_face_index < 0:
		replace_face_index = 0
	flea_market._on_swap_face_selected(replace_face_index)
	await wait_process_frames(2)
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_GO_TO_DICE_SELECT)

	assert_false(flea_market._ready_btn.disabled)
	assert_true(TutorialManager.report_action("go_to_dice_select"))
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_SELECT_REQUIRED_DICE)

	var dice_select: Node = DICE_SELECT_SCENE.instantiate()
	autoqfree(dice_select)
	add_child_autofree(dice_select)
	await wait_process_frames(3)

	var loaded_group_idx := _find_group_index_for_bag_index(dice_select, TutorialManager.loaded_die_index)
	var improved_group_idx := _find_group_index_for_bag_index(dice_select, TutorialManager.improved_die_index)
	var filler_group_idx := _find_non_required_group_index(dice_select)
	var required_targets: Array[Control] = dice_select._find_required_group_targets()

	assert_eq(required_targets.size(), 2)
	assert_true((dice_select._groups[loaded_group_idx]["card"] as ItemCard).is_accented())
	assert_true((dice_select._groups[improved_group_idx]["card"] as ItemCard).is_accented())

	dice_select._on_plus_pressed(loaded_group_idx)
	dice_select._on_plus_pressed(improved_group_idx)
	for _i in range(3):
		dice_select._on_plus_pressed(filler_group_idx)
	await wait_process_frames(2)

	var selected_indices: Array[int] = dice_select._get_selected_indices()
	assert_true(TutorialManager.selection_meets_requirements(selected_indices))
	assert_true(TutorialManager.report_action("confirm_selection", {"selected_indices": selected_indices}))
	GameManager.selected_dice = _build_selected_dice(selected_indices)
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_COMBAT_ROLL)

	var combat: Node = COMBAT_SCENE.instantiate()
	autoqfree(combat)
	add_child_autofree(combat)
	await wait_until(func(): return not combat._animating, 3.0, 0.05, "combat intro finished")

	assert_true(combat._combo_btn.disabled)
	combat._combo_btn.emit_signal("pressed")
	await wait_process_frames(2)
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_COMBAT_ROLL)
	assert_false(combat._combo_overlay.visible)

	combat._on_roll_pressed()
	assert_true(await wait_until(
		func():
			return TutorialManager.step_id == TutorialManager.STEP_COMBAT_OPEN_COMBOS \
				and combat.combat_mgr.current_roll_values() == TutorialManager.get_scripted_roll_values(0),
		3.0,
		0.05,
		"first roll resolved"
	))
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_COMBAT_OPEN_COMBOS)
	assert_eq_deep(combat.combat_mgr.current_roll_values(), TutorialManager.get_scripted_roll_values(0))
	assert_eq(combat.combat_mgr.rerolls_remaining, 2)
	assert_false(combat._combo_overlay.visible)
	assert_false(combat._combo_btn.disabled)

	combat._combo_btn.emit_signal("pressed")
	assert_true(await wait_until(
		func():
			return TutorialManager.step_id == TutorialManager.STEP_COMBAT_EXPLAIN_COMBOS \
				and combat._combo_overlay.visible,
		2.0,
		0.05,
		"combo overlay opened"
	))
	assert_eq(combat._tutorial_overlay._highlight_targets.size(), 1)
	assert_true(combat._tutorial_overlay._highlight_targets.has(combat._find_current_combo_row_panel()))
	assert_true(combat._tutorial_overlay._body_label.text.contains("6 + 2 + 3 + 4 + 6 = 21"))
	assert_true(combat._tutorial_overlay._body_label.text.contains("21 x 1.5 pair mult = 31 pts"))
	var tutorial_panel_rect := Rect2(combat._tutorial_overlay._panel.position, combat._tutorial_overlay._panel.size)
	var combo_dialog_rect := Rect2(combat._combo_dialog.global_position, combat._combo_dialog.size)
	assert_false(tutorial_panel_rect.intersects(combo_dialog_rect))
	combat._tutorial_overlay._next_btn.emit_signal("pressed")
	assert_true(await wait_until(
		func():
			return TutorialManager.step_id == TutorialManager.STEP_COMBAT_HOLD_PAIR \
				and not combat._combo_overlay.visible,
		2.0,
		0.05,
		"combo explanation acknowledged"
	))
	assert_eq(combat._tutorial_overlay._highlight_targets.size(), 2)
	for hold_index in TutorialManager.required_combat_hold_indices:
		assert_true(combat._tutorial_overlay._highlight_targets.has(combat._dice_cards[hold_index]))

	for hold_index in TutorialManager.required_combat_hold_indices:
		combat._on_die_clicked(hold_index)
	assert_true(await wait_until(
		func(): return TutorialManager.step_id == TutorialManager.STEP_COMBAT_REROLL,
		2.0,
		0.05,
		"hold requirement satisfied"
	))
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_COMBAT_REROLL)
	assert_true(combat.combat_mgr.can_roll())

	combat._on_roll_pressed()
	assert_true(await wait_until(
		func():
			return TutorialManager.step_id == TutorialManager.STEP_COMBAT_SCORE \
				and combat.combat_mgr.current_roll_values() == TutorialManager.get_scripted_roll_values(1),
		3.0,
		0.05,
		"second roll resolved"
	))
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_COMBAT_SCORE)
	assert_eq_deep(combat.combat_mgr.current_roll_values(), TutorialManager.get_scripted_roll_values(1))

	combat._on_score_pressed()
	assert_true(await wait_until(func(): return combat._result_overlay.visible, 2.0, 0.05, "result overlay visible"))
	await wait_process_frames(2)
	assert_true(combat._result_target_beaten)
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_COMBAT_WIN)
	assert_eq(combat._result_sub_label.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART)
	assert_lt(combat._result_next_btn.size.x, combat._result_panel.size.x * 0.6)

	assert_true(TutorialManager.report_action("combat_next_round"))
	assert_true(TutorialManager.completed)
	assert_false(TutorialManager.is_active())


func _find_shop_index(items: Array, item_id: String) -> int:
	for i in range(items.size()):
		if items[i].get("id", "") == item_id:
			return i
	return -1


func _find_group_index_for_bag_index(dice_select, bag_index: int) -> int:
	for i in range(dice_select._groups.size()):
		if dice_select._groups[i]["indices"].has(bag_index):
			return i
	return -1


func _find_non_required_group_index(dice_select) -> int:
	var required := TutorialManager.get_required_bag_indices()
	for i in range(dice_select._groups.size()):
		var group_indices: Array = dice_select._groups[i]["indices"]
		var is_required := false
		for group_index in group_indices:
			if required.has(int(group_index)):
				is_required = true
				break
		if not is_required:
			return i
	return -1


func _build_selected_dice(selected_indices: Array[int]) -> Array[Die]:
	var selected: Array[Die] = []
	var all_dice := GameManager.dice_bag.get_all()
	for bag_index in selected_indices:
		selected.append(all_dice[bag_index])
	return selected
