extends GutTest

const MapNode := preload("res://scripts/map/map_node.gd")


func test_constructs_with_fields() -> void:
	var node := MapNode.new(7, MapNode.NodeType.COMBAT, 3, [9, 10] as Array[int])
	assert_eq(node.id, 7)
	assert_eq(node.type, MapNode.NodeType.COMBAT)
	assert_eq(node.depth, 3)
	assert_eq(node.next_ids, [9, 10] as Array[int])


func test_node_type_values_distinct() -> void:
	assert_ne(MapNode.NodeType.COMBAT, MapNode.NodeType.SHOP)
	assert_ne(MapNode.NodeType.COMBAT, MapNode.NodeType.BOSS)
	assert_ne(MapNode.NodeType.SHOP, MapNode.NodeType.BOSS)


func test_default_next_ids_is_empty() -> void:
	var node := MapNode.new(1, MapNode.NodeType.SHOP, 1)
	assert_eq(node.next_ids.size(), 0)


func test_init_duplicates_next_ids_input() -> void:
	var original: Array[int] = [5, 6]
	var node := MapNode.new(1, MapNode.NodeType.COMBAT, 1, original)
	original[0] = 99
	original.append(7)
	assert_eq(node.next_ids, [5, 6] as Array[int])
