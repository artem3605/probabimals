class_name DiceSelectionModel
extends RefCounted


func build_groups(dice: Array[Die]) -> Array[Dictionary]:
	var groups: Array[Dictionary] = []
	var key_order: Array[String] = []
	var key_map: Dictionary = {}
	for i in dice.size():
		var die: Die = dice[i]
		var key := group_key(die)
		if not key_map.has(key):
			key_map[key] = {"die": die, "color": die.color, "total": 0, "selected": 0, "indices": []}
			key_order.append(key)
		key_map[key]["total"] += 1
		key_map[key]["indices"].append(i)
	for key in key_order:
		groups.append(key_map[key])
	return groups


func group_key(die: Die) -> String:
	var parts: Array[String] = []
	for face: DiceFace in die.faces:
		parts.append("%d:%d:%.2f" % [face.value, face.face_type, face.effect_value])
	parts.sort()
	return "%s|%s" % [die.color, "|".join(parts)]


func total_selected(groups: Array[Dictionary]) -> int:
	var total := 0
	for group in groups:
		total += int(group["selected"])
	return total


func increment(groups: Array[Dictionary], group_index: int, max_selection: int) -> bool:
	if group_index < 0 or group_index >= groups.size():
		return false
	var group := groups[group_index]
	if int(group["selected"]) >= int(group["total"]):
		return false
	if total_selected(groups) >= max_selection:
		return false
	group["selected"] = int(group["selected"]) + 1
	return true


func decrement(groups: Array[Dictionary], group_index: int) -> bool:
	if group_index < 0 or group_index >= groups.size():
		return false
	var group := groups[group_index]
	if int(group["selected"]) <= 0:
		return false
	group["selected"] = int(group["selected"]) - 1
	return true


func selected_indices(groups: Array[Dictionary]) -> Array[int]:
	var indices: Array[int] = []
	for group in groups:
		var count: int = int(group["selected"])
		if count <= 0:
			continue
		var group_indices: Array = group["indices"]
		for j in count:
			indices.append(int(group_indices[j]))
	return indices


func selected_dice(groups: Array[Dictionary], dice: Array[Die]) -> Array[Die]:
	var selected: Array[Die] = []
	for index in selected_indices(groups):
		selected.append(dice[index])
	return selected
