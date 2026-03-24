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
	GameManager._setup_intro_combat()

	var intro_combat: Node = COMBAT_SCENE.instantiate()
	autoqfree(intro_combat)
	add_child_autofree(intro_combat)
	await wait_until(func(): return not intro_combat._animating, 3.0, 0.05, "intro combat ready")

	assert_eq(TutorialManager.step_id, TutorialManager.STEP_INTRO_WELCOME)
	assert_true(intro_combat._tutorial_overlay.visible)
	assert_true(intro_combat._menu_btn.disabled)
	intro_combat._on_pause_pressed()
	assert_false(intro_combat._pause_overlay.visible)
	intro_combat._tutorial_overlay._next_btn.emit_signal("pressed")
	assert_true(await wait_until(
		func(): return TutorialManager.step_id == TutorialManager.STEP_INTRO_ROLL,
		2.0,
		0.05,
		"intro roll step"
	))
	assert_true(intro_combat._combo_btn.disabled)
	var first_intro_roll := [6, 3, 2, 5, 1]
	intro_combat._on_roll_pressed()
	assert_true(await wait_until(
		func():
			return TutorialManager.step_id == TutorialManager.STEP_INTRO_HOLD \
				and intro_combat.combat_mgr.current_roll_values() == first_intro_roll,
		3.0,
		0.05,
		"intro first roll"
	))
	assert_eq_deep(intro_combat.combat_mgr.current_roll_values(), [6, 3, 2, 5, 1])
	assert_eq_deep(TutorialManager.required_combat_hold_indices, [0])
	intro_combat._on_die_clicked(0)
	assert_true(await wait_until(
		func(): return TutorialManager.step_id == TutorialManager.STEP_INTRO_REROLL,
		2.0,
		0.05,
		"intro hold step"
	))
	assert_true(intro_combat.combat_mgr.is_held(0))
	var second_intro_roll := [6, 6, 1, 3, 5]
	intro_combat._on_roll_pressed()
	assert_true(await wait_until(
		func():
			return TutorialManager.step_id == TutorialManager.STEP_INTRO_PAIR \
				and intro_combat.combat_mgr.current_roll_values() == second_intro_roll,
		3.0,
		0.05,
		"intro reroll step"
	))
	assert_false(intro_combat._combo_btn.disabled)
	intro_combat._combo_btn.emit_signal("pressed")
	await wait_process_frames(2)
	assert_true(intro_combat._combo_overlay.visible)
	assert_false(intro_combat._tutorial_overlay.visible)
	intro_combat._combo_btn.emit_signal("pressed")
	assert_true(await wait_until(
		func():
			return TutorialManager.step_id == TutorialManager.STEP_INTRO_FINISH \
				and not intro_combat._combo_overlay.visible,
		2.0,
		0.05,
		"intro finish step"
	))

	GameManager.target_score = 31
	intro_combat.combat_mgr.target_score = 31
	intro_combat._on_score_pressed()
	assert_true(await wait_until(
		func():
			return TutorialManager.step_id == TutorialManager.STEP_INTRO_WIN \
				and intro_combat._result_overlay.visible \
				and intro_combat._result_target_beaten,
		3.0,
		0.05,
		"intro win overlay"
	))

	assert_true(TutorialManager.report_action("combat_next_round"))
	GameManager.current_round = 1
	GameManager.target_score = GameManager.BASE_TARGET
	GameManager.coins = 35
	GameManager.selected_dice.clear()
	TutorialManager.enter_scene(TutorialManager.SCENE_FLEA_MARKET)
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_MARKET_INTRO)

	var flea_market = FLEA_MARKET_SCENE.instantiate()
	autoqfree(flea_market)
	add_child_autofree(flea_market)
	await wait_process_frames(3)

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
	assert_eq(TutorialManager.improved_die_index, 0)
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
	assert_true(required_targets.has(dice_select._groups[loaded_group_idx]["card"]))
	assert_true(required_targets.has(dice_select._groups[improved_group_idx]["card"]))

	dice_select._on_plus_pressed(loaded_group_idx)
	dice_select._on_plus_pressed(improved_group_idx)
	for _i in range(3):
		dice_select._on_plus_pressed(filler_group_idx)
	await wait_process_frames(2)

	var selected_indices: Array[int] = dice_select._get_selected_indices()
	assert_true(TutorialManager.selection_meets_requirements(selected_indices))
	assert_true(TutorialManager.report_action("confirm_selection", {"selected_indices": selected_indices}))
	GameManager.selected_dice = _build_selected_dice(selected_indices)
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_COMBAT_GOOD_LUCK)

	var combat: Node = COMBAT_SCENE.instantiate()
	autoqfree(combat)
	add_child_autofree(combat)
	await wait_until(func(): return not combat._animating, 3.0, 0.05, "combat intro finished")

	assert_true(combat._tutorial_overlay.visible)
	assert_true(TutorialManager.is_combat_roll_allowed())
	combat._on_roll_pressed()
	assert_true(await wait_until(
		func(): return TutorialManager.completed and not TutorialManager.is_active(),
		3.0,
		0.05,
		"combat good luck completion"
	))
	assert_false(combat._menu_btn.disabled)


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
