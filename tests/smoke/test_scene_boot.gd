extends GutTest

const TestData = preload("res://tests/support/test_data.gd")

const MAIN_MENU_SCENE := preload("res://scenes/main_menu/main_menu.tscn")
const FLEA_MARKET_SCENE := preload("res://scenes/flea_market/flea_market_screen.tscn")
const DICE_SELECT_SCENE := preload("res://scenes/dice_select/dice_select_screen.tscn")
const COMBAT_SCENE := preload("res://scenes/combat/combat_screen.tscn")


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
