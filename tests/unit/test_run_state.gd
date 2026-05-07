extends GutTest

const MapNode := preload("res://scripts/map/map_node.gd")
const RunState := preload("res://scripts/map/run_state.gd")


func _build_state():
	# 3 levels: 1 -> 2 (two nodes) -> boss
	var n1 := MapNode.new(1, MapNode.NodeType.COMBAT, 1, [2, 3] as Array[int])
	var n2 := MapNode.new(2, MapNode.NodeType.COMBAT, 2, [4] as Array[int])
	var n3 := MapNode.new(3, MapNode.NodeType.SHOP, 2, [4] as Array[int])
	var n4 := MapNode.new(4, MapNode.NodeType.BOSS, 3, [] as Array[int])
	var state := RunState.new()
	state.nodes = {1: n1, 2: n2, 3: n3, 4: n4}
	state.current_node_id = -1
	state.seed = 42
	return state


func test_available_at_start_returns_level_one_nodes() -> void:
	var state = _build_state()
	var ids := state.available_node_ids()
	ids.sort()
	assert_eq(ids, [1] as Array[int])


func test_available_after_completing_node_returns_next_ids() -> void:
	var state = _build_state()
	state.enter_node(1)
	state.complete_current_node()
	var ids := state.available_node_ids()
	ids.sort()
	assert_eq(ids, [2, 3] as Array[int])


func test_available_after_entering_uncompleted_node_returns_empty() -> void:
	var state = _build_state()
	state.enter_node(1)

	assert_eq(state.available_node_ids().size(), 0)


func test_available_at_boss_returns_empty() -> void:
	var state = _build_state()
	state.current_node_id = 4
	assert_eq(state.available_node_ids().size(), 0)


func test_get_current_node_returns_null_at_start() -> void:
	var state = _build_state()
	assert_null(state.call("get_current_node"))


func test_get_current_node_returns_node_after_entering() -> void:
	var state = _build_state()
	state.current_node_id = 2
	var node = state.call("get_current_node")
	assert_not_null(node)
	assert_eq(node.id, 2)


func test_enter_node_records_visited_path_once() -> void:
	var state = _build_state()

	state.enter_node(1)
	state.enter_node(2)
	state.enter_node(2)

	assert_eq(state.current_node_id, 2)
	assert_eq(state.visited_node_ids, [1, 2] as Array[int])
	assert_true(state.has_visited(1))


func test_complete_current_node_records_completed_path_once() -> void:
	var state = _build_state()

	state.enter_node(1)
	state.complete_current_node()
	state.complete_current_node()

	assert_eq(state.completed_node_ids, [1] as Array[int])
	assert_true(state.has_completed(1))


func test_shop_state_is_saved_per_node_with_defensive_copies() -> void:
	var state = _build_state()
	var shop_state := {
		"offerings": [{"id": "loaded_die"}],
		"sold": [true],
		"reroll_count": 1,
	}

	state.set_shop_state(3, shop_state)
	shop_state["sold"][0] = false

	var restored: Dictionary = state.get_shop_state(3)
	assert_eq(restored["offerings"][0]["id"], "loaded_die")
	assert_eq(restored["sold"], [true])
	assert_eq(restored["reroll_count"], 1)
	restored["sold"][0] = false
	assert_eq(state.get_shop_state(3)["sold"], [true])
