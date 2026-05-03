class_name RunState
extends RefCounted

const MapNode := preload("res://scripts/map/map_node.gd")

var nodes: Dictionary = {}  # int -> MapNode
var current_node_id: int = -1  # -1 means no node entered yet
var seed: int = 0


func get_current_node() -> Variant:
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
