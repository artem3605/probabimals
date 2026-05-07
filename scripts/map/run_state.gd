class_name RunState
extends RefCounted

var nodes: Dictionary = {}
var current_node_id: int = -1
var seed: int = 0
var visited_node_ids: Array[int] = []
var completed_node_ids: Array[int] = []
var shop_states: Dictionary = {}


func get_current_node() -> MapNode:
	if current_node_id == -1:
		return null
	return nodes.get(current_node_id, null)


func enter_node(node_id: int) -> void:
	current_node_id = node_id
	if not visited_node_ids.has(node_id):
		visited_node_ids.append(node_id)


func complete_current_node() -> void:
	if current_node_id == -1:
		return
	if not completed_node_ids.has(current_node_id):
		completed_node_ids.append(current_node_id)


func has_visited(node_id: int) -> bool:
	return visited_node_ids.has(node_id)


func has_completed(node_id: int) -> bool:
	return completed_node_ids.has(node_id)


func set_shop_state(node_id: int, state: Dictionary) -> void:
	shop_states[node_id] = state.duplicate(true)


func get_shop_state(node_id: int) -> Dictionary:
	if not shop_states.has(node_id):
		return {}
	var state: Dictionary = shop_states[node_id]
	return state.duplicate(true)


func available_node_ids() -> Array[int]:
	var result: Array[int] = []
	if current_node_id == -1:
		for id_key in nodes.keys():
			var node: MapNode = nodes[id_key]
			if node.depth == 1:
				result.append(node.id)
		return result
	if not has_completed(current_node_id):
		return result
	var current: MapNode = nodes.get(current_node_id, null)
	if current == null:
		return result
	for next_id in current.next_ids:
		result.append(int(next_id))
	return result
