extends GutTest

const MapScreenScene := preload("res://scenes/map/map_screen.tscn")
const MapNodeButtonScene := preload("res://scenes/map/map_node_button.tscn")
const MapNode := preload("res://scripts/map/map_node.gd")
const RunState := preload("res://scripts/map/run_state.gd")


func before_each() -> void:
	var combat := MapNode.new(1, MapNode.NodeType.COMBAT, 1, [2] as Array[int])
	var boss := MapNode.new(2, MapNode.NodeType.BOSS, 2, [] as Array[int])
	var run := RunState.new()
	run.nodes = {1: combat, 2: boss}
	run.current_node_id = -1
	GameManager.current_run = run


func after_each() -> void:
	GameManager.current_run = null


func test_map_screen_instantiates_with_tiny_run() -> void:
	var map_screen: Control = MapScreenScene.instantiate()
	add_child_autofree(map_screen)
	await get_tree().process_frame

	assert_not_null(map_screen)
	assert_not_null(map_screen.get_node_or_null("%MapContainer"))


func test_map_screen_lays_out_path_bottom_to_top() -> void:
	var map_screen: Control = MapScreenScene.instantiate()
	add_child_autofree(map_screen)
	await get_tree().process_frame

	var start_pos: Vector2 = map_screen._position_by_id[map_screen.MAP_START_NODE_ID]
	var combat_pos: Vector2 = map_screen._position_by_id[1]
	var boss_pos: Vector2 = map_screen._position_by_id[2]
	assert_gt(start_pos.y, combat_pos.y)
	assert_gt(combat_pos.y, boss_pos.y)


func test_map_screen_draws_completed_start_combat_at_bottom() -> void:
	var map_screen: Control = MapScreenScene.instantiate()
	add_child_autofree(map_screen)
	await get_tree().process_frame

	var start_button: MapNodeButton = map_screen._button_by_id[map_screen.MAP_START_NODE_ID]
	var combat_button: MapNodeButton = map_screen._button_by_id[1]
	assert_eq(start_button.state, "completed")
	assert_eq(start_button.node_type, MapNode.NodeType.COMBAT)
	assert_gt(start_button.position.y, combat_button.position.y)


func test_map_node_buttons_describe_shop_and_dice_roll_actions() -> void:
	var button: MapNodeButton = MapNodeButtonScene.instantiate()
	add_child_autofree(button)
	await get_tree().process_frame

	button.configure(1, MapNode.NodeType.COMBAT, "available")
	assert_eq(button.tooltip_text, "Roll Dice")
	assert_eq(button.get_visible_caption(), "ROLL")

	button.configure(2, MapNode.NodeType.SHOP, "available")
	assert_eq(button.tooltip_text, "Shop")
	assert_eq(button.get_visible_caption(), "SHOP")

	button.configure(3, MapNode.NodeType.BOSS, "available")
	assert_eq(button.tooltip_text, "Boss")
	assert_eq(button.get_visible_caption(), "BOSS")


func test_map_screen_panel_fits_compact_viewport() -> void:
	var map_screen: Control = MapScreenScene.instantiate()
	var panel_size: Vector2 = map_screen._target_map_panel_size(Vector2(960, 540))
	map_screen.free()

	assert_lte(panel_size.x, 896.0)
	assert_lte(panel_size.y, 324.0)


func test_map_screen_keeps_visited_route_completed() -> void:
	var run := RunState.new()
	run.nodes = {
		1: MapNode.new(1, MapNode.NodeType.COMBAT, 1, [2] as Array[int]),
		2: MapNode.new(2, MapNode.NodeType.SHOP, 2, [] as Array[int]),
	}
	run.current_node_id = 2
	run.visited_node_ids = [1, 2] as Array[int]
	run.completed_node_ids = [1, 2] as Array[int]
	GameManager.current_run = run
	var map_screen: Control = MapScreenScene.instantiate()
	add_child_autofree(map_screen)
	await get_tree().process_frame

	assert_eq(map_screen._button_by_id[1].state, "completed")


func test_map_screen_uses_scrollable_tall_content_for_full_path() -> void:
	var nodes := {}
	for depth in range(1, 7):
		var next_ids: Array[int] = []
		if depth < 6:
			next_ids.append(depth + 1)
		nodes[depth] = MapNode.new(depth, MapNode.NodeType.COMBAT, depth, next_ids)

	var run := RunState.new()
	run.nodes = nodes
	run.current_node_id = -1
	GameManager.current_run = run
	var map_screen: Control = MapScreenScene.instantiate()
	add_child_autofree(map_screen)
	await get_tree().process_frame

	var visible_size: Vector2 = map_screen._map_scroll.custom_minimum_size
	assert_gt(map_screen._map_container.custom_minimum_size.y, visible_size.y)
	assert_gt(map_screen._position_by_id[5].y - map_screen._position_by_id[6].y, 100.0)


func test_map_screen_opens_near_next_available_node_after_progress() -> void:
	var nodes := {}
	for depth in range(1, 11):
		var next_ids: Array[int] = []
		if depth < 10:
			next_ids.append(depth + 1)
		nodes[depth] = MapNode.new(depth, MapNode.NodeType.COMBAT, depth, next_ids)

	var run := RunState.new()
	run.nodes = nodes
	run.current_node_id = 5
	run.visited_node_ids = [1, 2, 3, 4, 5] as Array[int]
	run.completed_node_ids = [1, 2, 3, 4, 5] as Array[int]
	GameManager.current_run = run
	var map_screen: Control = MapScreenScene.instantiate()
	add_child_autofree(map_screen)
	await wait_process_frames(3)

	var next_node_y: float = map_screen._position_by_id[6].y
	var visible_top := float(map_screen._map_scroll.scroll_vertical)
	var visible_bottom: float = visible_top + map_screen._map_scroll.custom_minimum_size.y
	assert_between(next_node_y, visible_top, visible_bottom)


func test_map_screen_keeps_depth_one_child_edges_dim_at_run_start() -> void:
	var run := RunState.new()
	run.nodes = {
		1: MapNode.new(1, MapNode.NodeType.COMBAT, 1, [2] as Array[int]),
		2: MapNode.new(2, MapNode.NodeType.COMBAT, 2, [] as Array[int]),
	}
	run.current_node_id = -1
	GameManager.current_run = run
	var map_screen: Control = MapScreenScene.instantiate()
	add_child_autofree(map_screen)
	await get_tree().process_frame

	var available := run.available_node_ids()
	assert_eq(map_screen._edge_color_for(run.nodes[1], 2, run, available), map_screen.EDGE_COLOR_DIM)
