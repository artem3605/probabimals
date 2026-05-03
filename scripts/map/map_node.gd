class_name MapNode
extends RefCounted

enum NodeType { COMBAT, SHOP, BOSS }

var id: int = -1
var type: NodeType = NodeType.COMBAT
var depth: int = 0
var next_ids: Array[int] = []


func _init(p_id: int = -1, p_type: NodeType = NodeType.COMBAT, p_depth: int = 0, p_next_ids: Array[int] = [] as Array[int]) -> void:
	id = p_id
	type = p_type
	depth = p_depth
	next_ids = p_next_ids.duplicate()
