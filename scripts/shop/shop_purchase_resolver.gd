class_name ShopPurchaseResolver
extends RefCounted


func purchase_item(manager: Variant, item: Dictionary) -> Dictionary:
	var cost: int = item.get("cost", 0)
	if manager.coins < cost:
		return _failure()

	var category: String = item.get("category", "")
	var modifier: Modifier = null
	if category == "modifier":
		modifier = Modifier.from_shop_item(item)
		if modifier == null:
			return _failure()

	manager.coins -= cost

	match category:
		"die":
			manager.dice_bag.add_die(_die_from_shop_item(item))
		"face":
			pass
		"modifier":
			_apply_modifier(manager, modifier)

	return _success_with_coin_change()


func purchase_face_swap(manager: Variant, die_index: int, face_index: int, new_face: DiceFace, cost: int) -> Dictionary:
	if manager.coins < cost:
		return _failure()
	manager.coins -= cost
	swap_face(manager, die_index, face_index, new_face)
	return _success_with_coin_change()


func swap_face(manager: Variant, die_index: int, face_index: int, new_face: DiceFace) -> void:
	var die: Die = manager.dice_bag.get_die(die_index)
	if die != null:
		die.swap_face(face_index, new_face)


func _die_from_shop_item(item: Dictionary) -> Die:
	var params: Dictionary = item.get("params", {})
	var die_color: String = params.get("color", "colorless")
	var die_name: String = item.get("name", "Basic Die")
	var die_description: String = item.get("description", "A standard six-sided die")
	var die_rarity: String = item.get("rarity", "common")
	if params.has("faces"):
		var int_faces: Array[int] = []
		for face in params["faces"]:
			int_faces.append(int(face))
		return Die.from_values(int_faces, die_color, die_name, die_description, die_rarity)
	return Die.new([], die_color, die_name, die_description, die_rarity)


func _apply_modifier(manager: Variant, modifier: Modifier) -> void:
	if modifier.effect == Modifier.Effect.ADD_REROLLS:
		manager.rerolls_per_hand += int(modifier.value)
	else:
		manager.modifiers.append(modifier)


func _success_with_coin_change() -> Dictionary:
	return {
		"success": true,
		"coins_changed": true,
	}


func _failure() -> Dictionary:
	return {
		"success": false,
		"coins_changed": false,
	}
