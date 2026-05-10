extends GutTest

const TestData = preload("res://tests/support/test_data.gd")

const MAIN_MENU_SCENE := preload("res://scenes/main_menu/main_menu.tscn")
const MAP_SCENE := preload("res://scenes/map/map_screen.tscn")
const FLEA_MARKET_SCENE := preload("res://scenes/flea_market/flea_market_screen.tscn")
const DICE_SELECT_SCENE := preload("res://scenes/dice_select/dice_select_screen.tscn")
const COMBAT_SCENE := preload("res://scenes/combat/combat_screen.tscn")
const MapNode := preload("res://scripts/map/map_node.gd")
const RunState := preload("res://scripts/map/run_state.gd")


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
	GameManager.current_run = null
	TutorialManager.completed = false
	TutorialManager.clear_active_tutorial()


func test_primary_scenes_instantiate_without_runtime_errors() -> void:
	var main_menu := MAIN_MENU_SCENE.instantiate()
	autoqfree(main_menu)
	add_child_autofree(main_menu)

	var flea_market := FLEA_MARKET_SCENE.instantiate()
	autoqfree(flea_market)
	add_child_autofree(flea_market)

	var dice_select := DICE_SELECT_SCENE.instantiate()
	autoqfree(dice_select)
	add_child_autofree(dice_select)

	GameManager.selected_dice = [
		TestData.die_from_values([1, 2, 3, 4, 5, 6]),
		TestData.die_from_values([1, 2, 3, 4, 5, 6]),
		TestData.die_from_values([1, 2, 3, 4, 5, 6]),
		TestData.die_from_values([1, 2, 3, 4, 5, 6]),
		TestData.die_from_values([1, 2, 3, 4, 5, 6]),
	]
	var combat := COMBAT_SCENE.instantiate()
	autoqfree(combat)
	add_child_autofree(combat)

	assert_not_null(main_menu)
	assert_not_null(flea_market)
	assert_not_null(dice_select)
	assert_not_null(combat)


func test_standard_gameplay_screens_share_high_top_bar_position() -> void:
	GameManager.current_run = _make_tiny_run()
	var map := MAP_SCENE.instantiate()
	autoqfree(map)
	add_child_autofree(map)

	var flea_market := FLEA_MARKET_SCENE.instantiate()
	autoqfree(flea_market)
	add_child_autofree(flea_market)

	var dice_select := DICE_SELECT_SCENE.instantiate()
	autoqfree(dice_select)
	add_child_autofree(dice_select)

	GameManager.selected_dice = [
		TestData.die_from_values([1, 2, 3, 4, 5, 6]),
		TestData.die_from_values([1, 2, 3, 4, 5, 6]),
		TestData.die_from_values([1, 2, 3, 4, 5, 6]),
		TestData.die_from_values([1, 2, 3, 4, 5, 6]),
		TestData.die_from_values([1, 2, 3, 4, 5, 6]),
	]
	var combat := COMBAT_SCENE.instantiate()
	autoqfree(combat)
	add_child_autofree(combat)
	await wait_process_frames(2)

	for screen in [map, flea_market, dice_select, combat]:
		var menu_btn: Button = _find_button_with_text(screen, "MENU")
		assert_not_null(menu_btn)
		if menu_btn != null:
			assert_lte(menu_btn.global_position.y, 44.0)


func test_flea_market_wrapped_description_labels_do_not_fit_to_content_width() -> void:
	var flea_market := FLEA_MARKET_SCENE.instantiate()
	autoqfree(flea_market)
	add_child_autofree(flea_market)
	await wait_process_frames(2)

	assert_eq(flea_market._desc_body.autowrap_mode, TextServer.AUTOWRAP_WORD)
	assert_false(flea_market._desc_body.fit_content)
	assert_eq(flea_market._swap_desc_body.autowrap_mode, TextServer.AUTOWRAP_WORD)
	assert_false(flea_market._swap_desc_body.fit_content)


func test_flea_market_skips_shop_card_shadows_before_first_layout() -> void:
	var flea_market := FLEA_MARKET_SCENE.instantiate()
	autoqfree(flea_market)
	add_child_autofree(flea_market)

	var first_card: Control = flea_market._shop_cards[0]
	assert_eq(first_card.global_position, Vector2.ZERO)
	assert_ne(first_card.size, Vector2.ZERO)
	assert_false(flea_market._should_draw_shop_card_shadow(first_card))


func test_combat_wrapped_description_label_does_not_fit_to_content_width() -> void:
	GameManager.selected_dice = [
		TestData.die_from_values([1, 2, 3, 4, 5, 6]),
		TestData.die_from_values([1, 2, 3, 4, 5, 6]),
		TestData.die_from_values([1, 2, 3, 4, 5, 6]),
		TestData.die_from_values([1, 2, 3, 4, 5, 6]),
		TestData.die_from_values([1, 2, 3, 4, 5, 6]),
	]
	var combat := COMBAT_SCENE.instantiate()
	autoqfree(combat)
	add_child_autofree(combat)
	await wait_process_frames(2)

	assert_eq(combat._desc_body.autowrap_mode, TextServer.AUTOWRAP_WORD)
	assert_false(combat._desc_body.fit_content)
	assert_eq(combat._desc_body.custom_minimum_size.x, 388.0)


func test_combat_wrapped_description_body_keeps_visible_height_on_hover() -> void:
	GameManager.selected_dice = [
		TestData.die_from_values([1, 2, 3, 4, 5, 6]),
		TestData.die_from_values([1, 2, 3, 4, 5, 6]),
		TestData.die_from_values([1, 2, 3, 4, 5, 6]),
		TestData.die_from_values([1, 2, 3, 4, 5, 6]),
		TestData.die_from_values([1, 2, 3, 4, 5, 6]),
	]
	var combat := COMBAT_SCENE.instantiate()
	autoqfree(combat)
	add_child_autofree(combat)
	await wait_process_frames(2)

	combat._on_card_hover_enter(combat._dice_cards[0])

	assert_true(combat._desc_body.visible)
	assert_gt(combat._desc_body.custom_minimum_size.y, 0.0)


func test_dice_select_wrapped_description_label_does_not_fit_to_content_width() -> void:
	var dice_select := DICE_SELECT_SCENE.instantiate()
	autoqfree(dice_select)
	add_child_autofree(dice_select)
	await wait_process_frames(2)

	assert_eq(dice_select._desc_body.autowrap_mode, TextServer.AUTOWRAP_WORD)
	assert_false(dice_select._desc_body.fit_content)
	assert_eq(dice_select._desc_body.custom_minimum_size.x, 388.0)


func test_dice_select_wrapped_description_body_keeps_visible_height_on_hover() -> void:
	var dice_select := DICE_SELECT_SCENE.instantiate()
	autoqfree(dice_select)
	add_child_autofree(dice_select)
	await wait_process_frames(2)

	dice_select._on_card_hover_enter(dice_select._groups[0]["card"])

	assert_true(dice_select._desc_panel.visible)
	assert_gt(dice_select._desc_body.custom_minimum_size.y, 0.0)


func test_main_menu_moves_tutorial_replay_into_settings() -> void:
	var main_menu = MAIN_MENU_SCENE.instantiate()
	autoqfree(main_menu)
	add_child_autofree(main_menu)
	await wait_process_frames(2)

	assert_null(main_menu.get_node_or_null("ButtonContainer/TutorialButton"))

	main_menu._on_settings_pressed()
	assert_true(main_menu._settings_overlay.visible)

	var tutorial_btn: Variant = _find_button_with_text(main_menu._settings_overlay, "TUTORIAL")
	assert_not_null(tutorial_btn)


func _find_button_with_text(root: Node, text: String):
	for child in root.find_children("*", "Button", true, false):
		if child is Button and child.text == text:
			return child
	return null


func _make_tiny_run() -> RunState:
	var combat := MapNode.new(1, MapNode.NodeType.COMBAT, 1, [2] as Array[int])
	var boss := MapNode.new(2, MapNode.NodeType.BOSS, 2, [] as Array[int])
	var run := RunState.new()
	run.nodes = {1: combat, 2: boss}
	run.current_node_id = -1
	return run
