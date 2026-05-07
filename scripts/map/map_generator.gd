class_name MapGenerator
extends RefCounted

const MapNodeRef := preload("res://scripts/map/map_node.gd")
const RunStateRef := preload("res://scripts/map/run_state.gd")


static func generate(p_seed: int, config: Dictionary) -> RunStateRef:
	var rng := RandomNumberGenerator.new()
	rng.seed = p_seed

	var depth: int = int(config["depth"])
	var min_nodes: int = int(config["min_nodes_per_level"])
	var max_nodes: int = int(config["max_nodes_per_level"])
	var shop_probability: float = float(config["shop_probability"])
	var max_consecutive_shops: int = int(config["max_consecutive_shops"])

	var levels: Array = []
	var next_id := 1
	var previous_count := 0

	for d in range(1, depth):
		var count := _random_level_count(rng, min_nodes, max_nodes, previous_count)
		var level: Array = []
		for _i in range(count):
			var node_type: int = MapNodeRef.NodeType.COMBAT
			if rng.randf() < shop_probability:
				node_type = MapNodeRef.NodeType.SHOP
			level.append(MapNodeRef.new(next_id, node_type, d))
			next_id += 1
		levels.append(level)
		previous_count = count

	levels.append([MapNodeRef.new(next_id, MapNodeRef.NodeType.BOSS, depth)])

	_connect_levels(levels, rng)
	_enforce_max_consecutive_shops(levels, max_consecutive_shops)

	var state := RunStateRef.new()
	state.seed = p_seed
	state.current_node_id = -1
	for level in levels:
		for node in level:
			state.nodes[node.id] = node
	return state


static func _connect_levels(levels: Array, rng: RandomNumberGenerator) -> void:
	for level_index in range(levels.size() - 1):
		var top: Array = levels[level_index]
		var bottom: Array = levels[level_index + 1]
		var edge_indices: Array = []
		for _i in range(top.size()):
			edge_indices.append([])

		for bottom_index in range(bottom.size()):
			var top_index := _scaled_index(bottom_index, bottom.size(), top.size())
			edge_indices[top_index].append(bottom_index)

		for top_index in range(top.size()):
			if edge_indices[top_index].is_empty():
				edge_indices[top_index].append(_scaled_index(top_index, top.size(), bottom.size()))

		for top_index in range(top.size()):
			if edge_indices[top_index].size() >= 2:
				continue
			if rng.randf() >= 0.5:
				continue
			var primary: int = edge_indices[top_index][0]
			var candidates: Array[int] = []
			if primary > 0:
				candidates.append(primary - 1)
			if primary < bottom.size() - 1:
				candidates.append(primary + 1)
			var valid_candidates: Array[int] = []
			for candidate in candidates:
				if (
					not edge_indices[top_index].has(candidate)
					and _can_add_non_crossing_edge(edge_indices, top_index, candidate)
				):
					valid_candidates.append(candidate)
			if valid_candidates.is_empty():
				continue
			var extra: int = valid_candidates[rng.randi_range(0, valid_candidates.size() - 1)]
			if not edge_indices[top_index].has(extra):
				edge_indices[top_index].append(extra)

		for top_index in range(top.size()):
			var node: MapNode = top[top_index]
			var next_ids: Array[int] = []
			for bottom_index in edge_indices[top_index]:
				var child: MapNode = bottom[int(bottom_index)]
				if not next_ids.has(child.id):
					next_ids.append(child.id)
			next_ids.sort()
			node.next_ids = next_ids


static func _random_level_count(rng: RandomNumberGenerator, min_nodes: int, max_nodes: int, previous_count: int) -> int:
	var effective_max := max_nodes
	if previous_count > 0:
		effective_max = min(effective_max, previous_count * 2)
	if effective_max < min_nodes:
		return effective_max
	return rng.randi_range(min_nodes, effective_max)


static func _scaled_index(index: int, source_count: int, target_count: int) -> int:
	if target_count <= 1 or source_count <= 1:
		return 0
	return int(round(float(index) * float(target_count - 1) / float(source_count - 1)))


static func _can_add_non_crossing_edge(edge_indices: Array, top_index: int, bottom_index: int) -> bool:
	for left_index in range(top_index):
		for left_bottom_index in edge_indices[left_index]:
			if int(left_bottom_index) > bottom_index:
				return false
	for right_index in range(top_index + 1, edge_indices.size()):
		for right_bottom_index in edge_indices[right_index]:
			if bottom_index > int(right_bottom_index):
				return false
	return true


static func _enforce_max_consecutive_shops(levels: Array, max_shops: int) -> void:
	var streaks := {}
	for level_index in range(levels.size()):
		var level: Array = levels[level_index]
		for node in level:
			var parent_streak := 0
			if level_index > 0:
				parent_streak = _max_parent_shop_streak(levels[level_index - 1], node.id, streaks)
			if node.type == MapNodeRef.NodeType.SHOP and parent_streak >= max_shops:
				node.type = MapNodeRef.NodeType.COMBAT
				streaks[node.id] = 0
			elif node.type == MapNodeRef.NodeType.SHOP:
				streaks[node.id] = parent_streak + 1
			else:
				streaks[node.id] = 0


static func _max_parent_shop_streak(parents: Array, node_id: int, streaks: Dictionary) -> int:
	var result := 0
	for parent in parents:
		var parent_node: MapNode = parent
		if parent_node.next_ids.has(node_id):
			result = max(result, int(streaks.get(parent_node.id, 0)))
	return result
