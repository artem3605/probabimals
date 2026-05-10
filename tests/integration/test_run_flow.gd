extends GutTest

const SHOP_SCENE := preload("res://scenes/shop/shop_screen.tscn")
const COMBAT_SCREEN_SCENE := preload("res://scenes/combat/combat_screen.tscn")
const DICE_SELECT_SCENE := preload("res://scenes/dice_select/dice_select_screen.tscn")
const MAP_SCREEN_SCENE := preload("res://scenes/map/map_screen.tscn")

var _original_current_run: RunState
var _original_current_phase: int
var _original_coins: int
var _original_total_score: int
var _original_target_score: int
var _original_hands_per_round: int
var _original_rerolls_per_hand: int
var _original_current_round: int
var _original_dice_bag: DiceBag
var _original_modifiers: Array[Modifier]
var _original_selected_dice: Array[Die]
var _original_last_run_result: Dictionary
var _original_save_path: String
var _original_tutorial_state: Dictionary
var _temp_paths: Array[String] = []


func before_each() -> void:
	_original_current_run = GameManager.current_run
	_original_current_phase = GameManager.current_phase
	_original_coins = GameManager.coins
	_original_total_score = GameManager.total_score
	_original_target_score = GameManager.target_score
	_original_hands_per_round = GameManager.hands_per_round
	_original_rerolls_per_hand = GameManager.rerolls_per_hand
	_original_current_round = GameManager.current_round
	_original_dice_bag = GameManager.dice_bag
	_original_modifiers.assign(GameManager.modifiers)
	_original_selected_dice.assign(GameManager.selected_dice)
	_original_last_run_result = GameManager.last_run_result.duplicate(true)
	_original_save_path = GameManager.save_path
	_original_tutorial_state = TutorialManager.build_save_data().duplicate(true)
	var save_path := "user://gut_run_flow_%d.json" % Time.get_ticks_usec()
	GameManager.save_path = save_path
	_temp_paths.append(save_path)
	GameManager.current_run = null
	GameManager.current_phase = GameManager.Phase.SHOP
	GameManager.coins = 50
	GameManager.total_score = 0
	GameManager.target_score = GameManager.BASE_TARGET
	GameManager.hands_per_round = 4
	GameManager.rerolls_per_hand = 3
	GameManager.current_round = 1
	GameManager.dice_bag = DiceBag.new()
	for _i in range(5):
		GameManager.dice_bag.add_die(Die.new())
	GameManager.modifiers.clear()
	GameManager.selected_dice.clear()
	GameManager.last_run_result = {}
	GameManager.clear_resolved_combat_result()
	_apply_inactive_tutorial_state()


func after_each() -> void:
	GameManager.current_run = _original_current_run
	GameManager.current_phase = _original_current_phase
	GameManager.coins = _original_coins
	GameManager.total_score = _original_total_score
	GameManager.target_score = _original_target_score
	GameManager.hands_per_round = _original_hands_per_round
	GameManager.rerolls_per_hand = _original_rerolls_per_hand
	GameManager.current_round = _original_current_round
	GameManager.dice_bag = _original_dice_bag
	GameManager.modifiers.assign(_original_modifiers)
	GameManager.selected_dice.assign(_original_selected_dice)
	GameManager.last_run_result = _original_last_run_result
	GameManager.save_path = _original_save_path
	GameManager.clear_resolved_combat_result()
	get_tree().paused = false
	for path in _temp_paths:
		GameManager.delete_save(path)
	_temp_paths.clear()
	TutorialManager.apply_save_data(_original_tutorial_state)


func _apply_inactive_tutorial_state() -> void:
	(
		TutorialManager
		. apply_save_data(
			{
				"mode": TutorialManager.MODE_INACTIVE,
				"step_id": "",
				"completed": true,
				"checkpoint_scene": "",
				"loaded_die_index": -1,
				"improved_die_index": -1,
				"selected_bag_indices": [],
				"required_combat_hold_indices": [],
			}
		)
	)


func _build_test_run_state(current_node_id: int) -> RunState:
	var state := RunState.new()
	state.nodes = {
		1: MapNode.new(1, MapNode.NodeType.COMBAT, 1, [2, 3] as Array[int]),
		2: MapNode.new(2, MapNode.NodeType.COMBAT, 2, [4] as Array[int]),
		3: MapNode.new(3, MapNode.NodeType.SHOP, 2, [4] as Array[int]),
		4: MapNode.new(4, MapNode.NodeType.BOSS, 3, [] as Array[int]),
	}
	state.current_node_id = current_node_id
	return state


func _build_boss_start_run_state() -> RunState:
	var state := RunState.new()
	state.nodes = {1: MapNode.new(1, MapNode.NodeType.BOSS, 1, [] as Array[int])}
	state.current_node_id = -1
	return state


func _add_shop_screen():
	var shop = SHOP_SCENE.instantiate()
	autoqfree(shop)
	add_child_autofree(shop)
	await wait_process_frames(2)
	return shop


func _add_combat_screen():
	var combat_screen = COMBAT_SCREEN_SCENE.instantiate()
	autoqfree(combat_screen)
	add_child_autofree(combat_screen)
	await wait_process_frames(2)
	return combat_screen


func _add_dice_select_screen():
	var dice_select = DICE_SELECT_SCENE.instantiate()
	autoqfree(dice_select)
	add_child_autofree(dice_select)
	await wait_process_frames(2)
	return dice_select


func _add_map_screen():
	var map_screen = MAP_SCREEN_SCENE.instantiate()
	autoqfree(map_screen)
	add_child_autofree(map_screen)
	await wait_process_frames(2)
	return map_screen


func _press_ready_button(shop) -> void:
	shop._ready_btn.emit_signal("pressed")
	await wait_process_frames(2)


func _press_menu_button(screen: Node) -> void:
	var menu_btn = _find_button_with_text(screen, "MENU")
	assert_not_null(menu_btn)
	if menu_btn != null:
		menu_btn.emit_signal("pressed")
	await wait_process_frames(2)


func _offering_ids(shop) -> Array[String]:
	var ids: Array[String] = []
	for item in shop._shop_offerings:
		ids.append(str(item.get("id", "")))
	return ids


func _first_direct_buy_index(shop) -> int:
	for i in range(shop._shop_offerings.size()):
		if str(shop._shop_offerings[i].get("category", "")) != "face":
			return i
	return -1


func _find_button_with_text(root: Node, text: String):
	for child in root.find_children("*", "Button", true, false):
		if child is Button and child.text == text:
			return child
	return null


func _read_current_save_data() -> Dictionary:
	var file := FileAccess.open(GameManager.save_path, FileAccess.READ)
	assert_not_null(file)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	return {}


func _apply_tutorial_step(step_id: String) -> void:
	(
		TutorialManager
		. apply_save_data(
			{
				"mode": TutorialManager.MODE_FIRST_RUN,
				"step_id": step_id,
				"completed": false,
				"checkpoint_scene": TutorialManager.SCENE_SHOP,
				"loaded_die_index": 5,
				"improved_die_index": 0,
				"selected_bag_indices": [],
				"required_combat_hold_indices": [],
			}
		)
	)


func test_shop_ready_button_says_continue_on_shop_run_node() -> void:
	GameManager.current_run = _build_test_run_state(3)

	var shop = await _add_shop_screen()

	assert_eq(shop._ready_btn.text, "CONTINUE")


func test_shop_ready_button_says_ready_outside_run() -> void:
	GameManager.current_run = null

	var shop = await _add_shop_screen()

	assert_eq(shop._ready_btn.text, "READY!")


func test_shop_ready_button_says_ready_at_run_start() -> void:
	GameManager.current_run = _build_test_run_state(-1)

	var shop = await _add_shop_screen()

	assert_eq(shop._ready_btn.text, "READY!")


func test_shop_ready_button_press_outside_run_goes_to_dice_select() -> void:
	GameManager.current_run = null

	var shop = await _add_shop_screen()
	await _press_ready_button(shop)

	assert_eq(GameManager.current_phase, GameManager.Phase.DICE_SELECT)


func test_shop_ready_button_press_on_shop_run_node_goes_to_map() -> void:
	GameManager.current_run = _build_test_run_state(3)

	var shop = await _add_shop_screen()
	assert_eq(shop._ready_btn.text, "CONTINUE")
	await _press_ready_button(shop)

	assert_eq(GameManager.current_phase, GameManager.Phase.MAP)


func test_shop_map_shop_state_survives_scene_reload_purchase_and_reroll() -> void:
	GameManager.current_run = _build_test_run_state(3)
	GameManager.current_run.seed = 123
	GameManager.current_phase = GameManager.Phase.SHOP
	GameManager.coins = 200

	var first_market = await _add_shop_screen()
	var first_ids := _offering_ids(first_market)
	var buy_index := _first_direct_buy_index(first_market)
	assert_gte(buy_index, 0)
	first_market._on_shop_item_buy(buy_index)
	await wait_process_frames(1)
	assert_true(first_market._sold[buy_index])
	assert_true(GameManager.has_save())

	var after_buy_market = await _add_shop_screen()
	assert_eq(_offering_ids(after_buy_market), first_ids)
	assert_true(after_buy_market._sold[buy_index])
	after_buy_market._on_reroll_pressed()
	await wait_process_frames(1)
	var rerolled_ids := _offering_ids(after_buy_market)
	assert_eq(GameManager.current_run.get_shop_state(3).get("reroll_count", -1), 1)

	var restored_market = await _add_shop_screen()
	assert_eq(_offering_ids(restored_market), rerolled_ids)
	assert_eq(restored_market._sold, [false, false, false, false, false])


func test_shop_menu_button_abandons_active_run_without_result() -> void:
	GameManager.current_run = _build_test_run_state(3)
	GameManager.current_phase = GameManager.Phase.SHOP
	GameManager.last_run_result = {}
	GameManager.save_game()
	assert_true(GameManager.can_load_save())

	var shop = await _add_shop_screen()
	await _press_menu_button(shop)

	assert_null(GameManager.current_run)
	assert_eq(GameManager.current_phase, GameManager.Phase.MAIN_MENU)
	assert_eq_deep(GameManager.last_run_result, {})
	assert_false(GameManager.has_save())
	assert_false(GameManager.can_load_save())


func test_shop_ready_button_reports_tutorial_go_to_dice_select() -> void:
	_apply_tutorial_step(TutorialManager.STEP_GO_TO_DICE_SELECT)

	var shop = await _add_shop_screen()
	await _press_ready_button(shop)

	assert_eq(TutorialManager.step_id, TutorialManager.STEP_SELECT_REQUIRED_DICE)
	assert_eq(GameManager.current_phase, GameManager.Phase.DICE_SELECT)


func test_shop_ready_button_during_first_run_keeps_tutorial_on_dice_select() -> void:
	_apply_tutorial_step(TutorialManager.STEP_GO_TO_DICE_SELECT)
	GameManager.current_run = _build_test_run_state(-1)
	GameManager.current_phase = GameManager.Phase.SHOP

	var shop = await _add_shop_screen()
	await _press_ready_button(shop)

	assert_eq(TutorialManager.step_id, TutorialManager.STEP_SELECT_REQUIRED_DICE)
	assert_eq(GameManager.current_phase, GameManager.Phase.DICE_SELECT)
	assert_not_null(GameManager.current_run)
	assert_eq(GameManager.current_run.current_node_id, -1)


func test_combat_pause_quit_abandons_active_run_without_defeat_result() -> void:
	GameManager.current_run = _build_test_run_state(1)
	GameManager.current_phase = GameManager.Phase.COMBAT
	GameManager.last_run_result = {}
	GameManager.save_game()
	assert_true(GameManager.can_load_save())

	var combat_screen = await _add_combat_screen()
	combat_screen.combat_mgr.running_score = 42
	combat_screen._pause_overlay.visible = true
	get_tree().paused = true
	combat_screen._on_pause_quit_pressed()
	await wait_seconds(0.45)

	assert_null(GameManager.current_run)
	assert_eq(GameManager.current_phase, GameManager.Phase.MAIN_MENU)
	assert_eq_deep(GameManager.last_run_result, {})
	assert_false(GameManager.has_save())
	assert_false(GameManager.can_load_save())


func test_combat_victory_result_overlay_saves_resolved_map_state() -> void:
	GameManager.current_run = _build_test_run_state(1)
	GameManager.current_phase = GameManager.Phase.COMBAT
	GameManager.current_round = 1
	GameManager.coins = 50
	GameManager.save_game()
	assert_true(GameManager.can_load_save())

	var combat_screen = await _add_combat_screen()
	combat_screen._on_combat_ended(GameManager.target_score, true)
	await wait_process_frames(1)

	var saved := _read_current_save_data()
	var completed_node_ids: Array[int] = []
	for id in saved.get("current_run", {}).get("completed_node_ids", []):
		completed_node_ids.append(int(id))
	assert_eq(saved.get("phase"), "MAP")
	assert_eq(saved.get("current_round"), 2)
	assert_eq(saved.get("coins"), 65)
	assert_eq(completed_node_ids, [1] as Array[int])
	assert_true(combat_screen._result_overlay.visible)


func test_combat_defeat_result_overlay_deletes_active_run_save() -> void:
	GameManager.current_run = _build_test_run_state(1)
	GameManager.current_phase = GameManager.Phase.COMBAT
	GameManager.last_run_result = {}
	GameManager.save_game()
	assert_true(GameManager.can_load_save())

	var combat_screen = await _add_combat_screen()
	combat_screen._on_combat_ended(12, false)
	await wait_process_frames(1)

	assert_false(GameManager.has_save())
	assert_false(GameManager.can_load_save())
	assert_null(GameManager.current_run)
	assert_eq_deep(GameManager.last_run_result, {"victory": false, "round": 1, "total_score": 12, "coins": 50})
	assert_true(combat_screen._result_overlay.visible)


func test_combat_boss_victory_overlay_uses_terminal_copy() -> void:
	GameManager.current_run = _build_boss_start_run_state()
	GameManager.current_run.enter_node(1)
	GameManager.current_phase = GameManager.Phase.COMBAT
	GameManager.current_round = 10
	GameManager.target_score = 300

	var combat_screen = await _add_combat_screen()
	combat_screen._show_result_overlay(420, true)

	assert_eq(combat_screen._result_message.text, "BOSS DEFEATED!")
	assert_eq(combat_screen._result_sub_label.text, "Final target: 300")
	assert_eq(combat_screen._result_next_btn.text, "FINISH RUN")
	assert_true(combat_screen._result_next_btn.visible)


func test_dice_select_menu_button_abandons_active_run_without_result() -> void:
	GameManager.current_run = _build_test_run_state(1)
	GameManager.current_phase = GameManager.Phase.DICE_SELECT
	GameManager.last_run_result = {}
	GameManager.save_game()
	assert_true(GameManager.can_load_save())

	var dice_select = await _add_dice_select_screen()
	await _press_menu_button(dice_select)

	assert_null(GameManager.current_run)
	assert_eq(GameManager.current_phase, GameManager.Phase.MAIN_MENU)
	assert_eq_deep(GameManager.last_run_result, {})
	assert_false(GameManager.has_save())
	assert_false(GameManager.can_load_save())


func test_map_menu_button_abandons_active_run_without_result() -> void:
	GameManager.current_run = _build_test_run_state(1)
	GameManager.current_phase = GameManager.Phase.MAP
	GameManager.last_run_result = {}
	GameManager.save_game()
	assert_true(GameManager.can_load_save())

	var map_screen = await _add_map_screen()
	await _press_menu_button(map_screen)

	assert_null(GameManager.current_run)
	assert_eq(GameManager.current_phase, GameManager.Phase.MAIN_MENU)
	assert_eq_deep(GameManager.last_run_result, {})
	assert_false(GameManager.has_save())
	assert_false(GameManager.can_load_save())


func test_enter_boss_map_node_multiplies_target_and_routes_to_dice_select() -> void:
	var base_target := 200
	var boss_multiplier := float(DataManager.get_map_config().get("boss_blind_multiplier", 1.5))
	GameManager.current_run = _build_boss_start_run_state()
	GameManager.current_phase = GameManager.Phase.MAP
	GameManager.target_score = base_target

	GameManager.enter_map_node(1)

	assert_eq(GameManager.current_run.current_node_id, 1)
	assert_eq(GameManager.target_score, int(floor(float(base_target) * boss_multiplier)))
	assert_eq(GameManager.current_phase, GameManager.Phase.DICE_SELECT)
