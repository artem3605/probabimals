class_name RunState
extends RefCounted

var nodes: Dictionary = {}
var current_node_id: int = -1
var seed: int = 0


func get_current_node() -> MapNode:
	if current_node_id == -1:
		return null
	return nodes.get(current_node_id, null)


func available_node_ids() -> Array[int]:
	var result: Array[int] = []
	if current_node_id == -1:
		for id_key in nodes.keys():
			var node: MapNode = nodes[id_key]
			if node.depth == 1:
				result.append(node.id)
		return result
	var current: MapNode = nodes.get(current_node_id, null)
	if current == null:
		return result
	for next_id in current.next_ids:
		result.append(int(next_id))
	return result
