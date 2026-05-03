extends GutTest

const MapNode := preload("res://scripts/map/map_node.gd")
const RunState := preload("res://scripts/map/run_state.gd")


func _build_state() -> RunState:
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
	var state := _build_state()
	var ids := state.available_node_ids()
	ids.sort()
	assert_eq(ids, [1] as Array[int])


func test_available_after_entering_node_returns_next_ids() -> void:
	var state := _build_state()
	state.current_node_id = 1
	var ids := state.available_node_ids()
	ids.sort()
	assert_eq(ids, [2, 3] as Array[int])


func test_available_at_boss_returns_empty() -> void:
	var state := _build_state()
	state.current_node_id = 4
	assert_eq(state.available_node_ids().size(), 0)


func test_get_current_node_returns_null_at_start() -> void:
	var state := _build_state()
	assert_null(state.get_current_node())


func test_get_current_node_returns_node_after_entering() -> void:
	var state := _build_state()
	state.current_node_id = 2
	var node: MapNode = state.get_current_node()
	assert_not_null(node)
	assert_eq(node.id, 2)
