extends GutTest


func test_data_manager_exposes_map_config() -> void:
	var cfg := DataManager.get_map_config()
	assert_true(cfg is Dictionary)
	assert_true(cfg.has("depth"))
	assert_true(cfg.has("min_nodes_per_level"))
	assert_true(cfg.has("max_nodes_per_level"))
	assert_true(cfg.has("shop_probability"))
	assert_true(cfg.has("max_consecutive_shops"))
	assert_true(cfg.has("boss_blind_multiplier"))


func test_map_config_values_are_sane() -> void:
	var cfg := DataManager.get_map_config()
	assert_true(int(cfg["depth"]) >= 2)
	assert_true(int(cfg["min_nodes_per_level"]) >= 1)
	assert_true(int(cfg["max_nodes_per_level"]) >= int(cfg["min_nodes_per_level"]))
	var shop_prob := float(cfg["shop_probability"])
	assert_true(shop_prob >= 0.0 and shop_prob <= 1.0)
	assert_true(int(cfg["max_consecutive_shops"]) >= 0)
	assert_true(float(cfg["boss_blind_multiplier"]) >= 1.0)


func test_default_map_depth_is_ten_levels() -> void:
	var cfg := DataManager.get_map_config()
	assert_eq(int(cfg["depth"]), 10)


func test_invalid_map_config_fallbacks_keep_min_max_consistent() -> void:
	var cfg := (
		DataManager
		. _validated_map_config(
			{
				"depth": 1,
				"min_nodes_per_level": 10,
				"max_nodes_per_level": 2,
				"shop_probability": 2.0,
				"max_consecutive_shops": -1,
				"boss_blind_multiplier": 0.5,
			}
		)
	)
	assert_push_error(5)
	assert_eq(int(cfg["depth"]), 10)
	assert_true(int(cfg["depth"]) >= 2)
	assert_eq(int(cfg["min_nodes_per_level"]), 1)
	assert_eq(int(cfg["max_nodes_per_level"]), 3)
	var shop_prob := float(cfg["shop_probability"])
	assert_true(shop_prob >= 0.0 and shop_prob <= 1.0)
	assert_true(int(cfg["max_consecutive_shops"]) >= 0)
	assert_true(float(cfg["boss_blind_multiplier"]) >= 1.0)


func _generator_script() -> Variant:
	var script = load("res://scripts/map/map_generator.gd")
	assert_not_null(script)
	return script


func _generate(seed: int) -> Variant:
	var script = _generator_script()
	if script == null:
		return null
	return script.generate(seed, DataManager.get_map_config())


func _assert_generated(seed: int) -> Variant:
	var state = _generate(seed)
	assert_not_null(state)
	return state


func test_generate_returns_run_state() -> void:
	var state = _assert_generated(12345)
	if state == null:
		return
	assert_eq(state.current_node_id, -1)
	assert_eq(state.seed, 12345)


func test_levels_match_depth() -> void:
	var cfg := DataManager.get_map_config()
	var state = _assert_generated(1)
	if state == null:
		return
	var depth: int = int(cfg["depth"])
	var counts := {}
	for id_key in state.nodes.keys():
		var node: MapNode = state.nodes[id_key]
		counts[node.depth] = int(counts.get(node.depth, 0)) + 1
	for d in range(1, depth + 1):
		assert_true(counts.has(d), "missing nodes at depth %d" % d)
		assert_true(int(counts[d]) >= 1, "no nodes at depth %d" % d)


func test_boss_is_unique_at_max_depth() -> void:
	var cfg := DataManager.get_map_config()
	var state = _assert_generated(2)
	if state == null:
		return
	var depth: int = int(cfg["depth"])
	var boss_count := 0
	for id_key in state.nodes.keys():
		var node: MapNode = state.nodes[id_key]
		if node.type == MapNode.NodeType.BOSS:
			boss_count += 1
			assert_eq(node.depth, depth)
			assert_eq(node.next_ids.size(), 0)
	assert_eq(boss_count, 1)


func test_non_boss_nodes_have_one_or_two_outgoing_edges() -> void:
	var state = _assert_generated(3)
	if state == null:
		return
	for id_key in state.nodes.keys():
		var node: MapNode = state.nodes[id_key]
		if node.type != MapNode.NodeType.BOSS:
			assert_between(node.next_ids.size(), 1, 2, "node %d has %d next_ids" % [node.id, node.next_ids.size()])


func test_width_one_level_does_not_fan_out_to_three_children() -> void:
	var cfg := DataManager.get_map_config()
	cfg["depth"] = 5
	cfg["min_nodes_per_level"] = 1
	cfg["max_nodes_per_level"] = 3
	cfg["shop_probability"] = 0.0
	var script = _generator_script()
	if script == null:
		return
	var seed := 4
	var state = script.generate(seed, cfg)
	assert_not_null(state)
	if state == null:
		return
	for id_key in state.nodes.keys():
		var node: MapNode = state.nodes[id_key]
		if node.type != MapNode.NodeType.BOSS:
			assert_between(
				node.next_ids.size(),
				1,
				2,
				"seed %d node %d at depth %d has %d next_ids" % [seed, node.id, node.depth, node.next_ids.size()]
			)


func test_generated_edges_do_not_cross() -> void:
	var cfg := DataManager.get_map_config()
	cfg["depth"] = 4
	cfg["min_nodes_per_level"] = 2
	cfg["max_nodes_per_level"] = 3
	cfg["shop_probability"] = 0.5
	var script = _generator_script()
	if script == null:
		return
	for seed in range(200):
		var state = script.generate(seed, cfg)
		assert_not_null(state)
		if state == null:
			return
		_assert_non_crossing_edges(state, seed)


func test_all_nodes_reachable_from_start() -> void:
	var state = _assert_generated(4)
	if state == null:
		return
	var visited := {}
	var queue: Array[int] = []
	for id_key in state.nodes.keys():
		var node: MapNode = state.nodes[id_key]
		if node.depth == 1:
			queue.append(node.id)
			visited[node.id] = true
	while not queue.is_empty():
		var cur: int = queue.pop_front()
		var n: MapNode = state.nodes[cur]
		for next_id in n.next_ids:
			if not visited.has(int(next_id)):
				visited[int(next_id)] = true
				queue.append(int(next_id))
	assert_eq(visited.size(), state.nodes.size())


func test_determinism_same_seed_same_map() -> void:
	var a = _assert_generated(777)
	var b = _assert_generated(777)
	if a == null or b == null:
		return
	assert_eq(a.nodes.size(), b.nodes.size())
	for id_key in a.nodes.keys():
		assert_true(b.nodes.has(id_key))
		var na: MapNode = a.nodes[id_key]
		var nb: MapNode = b.nodes[id_key]
		assert_eq(na.type, nb.type)
		assert_eq(na.depth, nb.depth)
		var na_next := na.next_ids.duplicate()
		var nb_next := nb.next_ids.duplicate()
		na_next.sort()
		nb_next.sort()
		assert_eq(na_next, nb_next)


func test_no_path_exceeds_max_consecutive_shops() -> void:
	var cfg := DataManager.get_map_config()
	cfg["max_consecutive_shops"] = 2
	cfg["shop_probability"] = 0.95
	var script = _generator_script()
	if script == null:
		return
	var state = script.generate(98765, cfg)
	assert_not_null(state)
	if state == null:
		return
	for id_key in state.nodes.keys():
		var node: MapNode = state.nodes[id_key]
		if node.depth == 1:
			_walk(state, node.id, 0, int(cfg["max_consecutive_shops"]))


func _walk(state, node_id: int, current_run_count: int, limit: int) -> void:
	var node: MapNode = state.nodes[node_id]
	var run_after := 0
	if node.type == MapNode.NodeType.SHOP:
		run_after = current_run_count + 1
	assert_true(run_after <= limit, "shop streak %d exceeds %d at node %d" % [run_after, limit, node_id])
	for next_id in node.next_ids:
		_walk(state, int(next_id), run_after, limit)


func _assert_non_crossing_edges(state, seed: int) -> void:
	var levels := {}
	for id_key in state.nodes.keys():
		var node: MapNode = state.nodes[id_key]
		if not levels.has(node.depth):
			levels[node.depth] = []
		levels[node.depth].append(node)

	var depths := levels.keys()
	depths.sort()
	for depth in depths:
		if not levels.has(int(depth) + 1):
			continue
		var top: Array = levels[depth]
		var bottom: Array = levels[int(depth) + 1]
		top.sort_custom(_sort_nodes_by_id)
		bottom.sort_custom(_sort_nodes_by_id)
		var bottom_positions := {}
		for bottom_index in range(bottom.size()):
			var bottom_node: MapNode = bottom[bottom_index]
			bottom_positions[bottom_node.id] = bottom_index
		for left_index in range(top.size()):
			var left_node: MapNode = top[left_index]
			for right_index in range(left_index + 1, top.size()):
				var right_node: MapNode = top[right_index]
				for left_next_id in left_node.next_ids:
					for right_next_id in right_node.next_ids:
						assert_true(
							int(bottom_positions[int(left_next_id)]) <= int(bottom_positions[int(right_next_id)]),
							(
								"crossing edge at seed %d depth %d: %d->%d crosses %d->%d"
								% [
									seed,
									int(depth),
									left_node.id,
									int(left_next_id),
									right_node.id,
									int(right_next_id),
								]
							)
						)


func _sort_nodes_by_id(a: MapNode, b: MapNode) -> bool:
	return a.id < b.id
