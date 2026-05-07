class_name SaveDataCodec
extends RefCounted

const RunStateRef := preload("res://scripts/map/run_state.gd")
const MapNodeRef := preload("res://scripts/map/map_node.gd")

const SAVE_FORMAT_VERSION := 2
const DEFAULT_STARTING_COINS := 10
const DEFAULT_TARGET_SCORE := 150
const DEFAULT_HANDS_PER_ROUND := 4
const DEFAULT_REROLLS_PER_HAND := 3
const DEFAULT_CURRENT_ROUND := 1
const DEFAULT_LOAD_PHASE := "FLEA_MARKET"


func build_save_data(manager, tutorial_manager, app_version: String, pending_combat_result_phase: int) -> Dictionary:
	var save_phase: int = int(manager.current_phase)
	if pending_combat_result_phase >= 0:
		save_phase = pending_combat_result_phase
	elif not tutorial_manager.is_active():
		if save_phase == manager.Phase.COMBAT:
			save_phase = manager.Phase.DICE_SELECT if manager.current_run != null else manager.Phase.FLEA_MARKET
		elif save_phase == manager.Phase.MAP and manager.current_run == null:
			save_phase = manager.Phase.FLEA_MARKET

	var data := {
		"save_version": SAVE_FORMAT_VERSION,
		"app_version": app_version,
		"phase": manager.Phase.keys()[save_phase],
		"coins": manager.coins,
		"total_score": manager.total_score,
		"target_score": manager.target_score,
		"hands_per_round": manager.hands_per_round,
		"rerolls_per_hand": manager.rerolls_per_hand,
		"current_round": manager.current_round,
		"dice_bag": _serialize_dice_bag(manager.dice_bag),
		"selected_dice_indices": _serialize_selected_dice_indices(manager.dice_bag, manager.selected_dice),
		"modifiers": _serialize_modifiers(manager.modifiers),
		"tutorial_completed": tutorial_manager.completed,
		"tutorial_mode": tutorial_manager.mode,
		"tutorial_step_id": tutorial_manager.step_id,
		"tutorial_state": tutorial_manager.build_save_data(),
	}
	if manager.current_run != null:
		data["current_run"] = _serialize_run_state(manager.current_run)
	return data


func apply_save_data(manager, tutorial_manager, data: Dictionary, fallback_phase: int, app_version: String) -> int:
	var normalized := normalize_save_data(data, app_version)
	if normalized.is_empty():
		return fallback_phase
	return apply_normalized_save_data(manager, tutorial_manager, normalized)


func apply_normalized_save_data(manager, tutorial_manager, data: Dictionary) -> int:
	manager.clear_resolved_combat_result()
	manager.coins = int(data.get("coins", DEFAULT_STARTING_COINS))
	manager.total_score = int(data.get("total_score", 0))
	manager.target_score = int(data.get("target_score", DEFAULT_TARGET_SCORE))
	manager.hands_per_round = int(data.get("hands_per_round", DEFAULT_HANDS_PER_ROUND))
	manager.rerolls_per_hand = int(data.get("rerolls_per_hand", DEFAULT_REROLLS_PER_HAND))
	manager.current_round = int(data.get("current_round", DEFAULT_CURRENT_ROUND))
	manager.dice_bag = _deserialize_dice_bag(data.get("dice_bag", []))
	manager.modifiers = _deserialize_modifiers(data.get("modifiers", []))
	manager.selected_dice = _deserialize_selected_dice(manager.dice_bag, data.get("selected_dice_indices", []))
	manager.current_run = _deserialize_run_state(data.get("current_run", {}))
	manager.last_run_result = {}
	var tutorial_state: Dictionary = data.get("tutorial_state", {})
	if tutorial_state.is_empty():
		tutorial_state = {
			"completed": bool(data.get("tutorial_completed", false)),
			"mode": str(data.get("tutorial_mode", tutorial_manager.MODE_INACTIVE)),
			"step_id": str(data.get("tutorial_step_id", "")),
		}
	tutorial_manager.apply_save_data(tutorial_state)
	return _phase_from_save_name(manager, str(data.get("phase", DEFAULT_LOAD_PHASE)))


func normalize_save_data(data: Dictionary, app_version: String) -> Dictionary:
	if data.is_empty():
		return {}
	return _migrate_save_data(data, _extract_save_version(data), app_version)


func _extract_save_version(data: Dictionary) -> int:
	if data.has("save_version"):
		return int(data.get("save_version", SAVE_FORMAT_VERSION))
	return 0


func _migrate_save_data(data: Dictionary, from_version: int, app_version: String) -> Dictionary:
	var migrated := data.duplicate(true)
	if from_version >= 0 and from_version < SAVE_FORMAT_VERSION:
		migrated["save_version"] = SAVE_FORMAT_VERSION
		if not migrated.has("app_version"):
			migrated["app_version"] = "legacy"
		return migrated
	if from_version == SAVE_FORMAT_VERSION:
		if not migrated.has("app_version"):
			migrated["app_version"] = app_version
		return migrated
	return {}


func _serialize_dice_bag(dice_bag: DiceBag) -> Array:
	var dice_arr: Array = []
	for d in dice_bag.get_all():
		dice_arr.append(_serialize_die(d))
	return dice_arr


func _serialize_run_state(run: RunStateRef) -> Dictionary:
	var node_arr: Array = []
	var node_ids := run.nodes.keys()
	node_ids.sort()
	for id_key in node_ids:
		var node: MapNodeRef = run.nodes[id_key]
		var serialized_node := {
			"id": node.id,
			"type": MapNodeRef.NodeType.keys()[node.type],
			"depth": node.depth,
			"next_ids": node.next_ids.duplicate(),
		}
		node_arr.append(serialized_node)
	return {
		"seed": run.seed,
		"current_node_id": run.current_node_id,
		"visited_node_ids": run.visited_node_ids.duplicate(),
		"completed_node_ids": run.completed_node_ids.duplicate(),
		"shop_states": _serialize_shop_states(run.shop_states),
		"nodes": node_arr,
	}


func _deserialize_run_state(raw: Variant) -> RunStateRef:
	if not (raw is Dictionary):
		return null
	var raw_dict: Dictionary = raw
	var raw_nodes: Variant = raw_dict.get("nodes", [])
	if not (raw_nodes is Array):
		return null
	var run := RunStateRef.new()
	run.seed = int(raw_dict.get("seed", 0))
	run.current_node_id = int(raw_dict.get("current_node_id", -1))
	run.visited_node_ids = _int_array_from_variant(raw_dict.get("visited_node_ids", []))
	run.completed_node_ids = _int_array_from_variant(raw_dict.get("completed_node_ids", []))
	run.shop_states = _deserialize_shop_states(raw_dict.get("shop_states", {}))
	for raw_node in raw_nodes:
		if not (raw_node is Dictionary):
			continue
		var node_dict: Dictionary = raw_node
		var next_ids := _int_array_from_variant(node_dict.get("next_ids", []))
		var node := MapNodeRef.new(
			int(node_dict.get("id", -1)),
			_map_node_type_from_save(str(node_dict.get("type", "COMBAT"))),
			int(node_dict.get("depth", 0)),
			next_ids
		)
		if node.id >= 0:
			run.nodes[node.id] = node
	if run.nodes.is_empty():
		return null
	return run


func _serialize_shop_states(shop_states: Dictionary) -> Dictionary:
	var result := {}
	for node_id in shop_states.keys():
		result[str(node_id)] = shop_states[node_id].duplicate(true)
	return result


func _deserialize_shop_states(raw: Variant) -> Dictionary:
	var result := {}
	if not (raw is Dictionary):
		return result
	var raw_dict: Dictionary = raw
	for key in raw_dict.keys():
		if raw_dict[key] is Dictionary:
			result[int(key)] = raw_dict[key].duplicate(true)
	return result


func _int_array_from_variant(raw: Variant) -> Array[int]:
	var result: Array[int] = []
	if raw is Array:
		for value in raw:
			result.append(int(value))
	return result


func _map_node_type_from_save(raw_type: String) -> MapNodeRef.NodeType:
	var type_idx := MapNodeRef.NodeType.keys().find(raw_type)
	if type_idx < 0:
		type_idx = MapNodeRef.NodeType.COMBAT
	return type_idx as MapNodeRef.NodeType


func _serialize_selected_dice_indices(dice_bag: DiceBag, selected_dice: Array[Die]) -> Array:
	var used_indices: Array[int] = []
	var indices: Array = []
	var all_dice := dice_bag.get_all()
	for selected_die in selected_dice:
		for i in range(all_dice.size()):
			if used_indices.has(i):
				continue
			if all_dice[i] == selected_die:
				indices.append(i)
				used_indices.append(i)
				break
	return indices


func _serialize_die(die: Die) -> Dictionary:
	var face_data: Array = []
	for f in die.faces:
		face_data.append(_serialize_face(f))
	return {
		"faces": face_data,
		"color": die.color,
		"name": die.die_name,
		"description": die.description,
		"rarity": die.rarity,
	}


func _serialize_face(face: DiceFace) -> Dictionary:
	return {
		"id": face.id,
		"value": face.value,
		"face_type": DiceFace.Type.keys()[face.face_type].to_lower(),
		"effect_value": face.effect_value,
		"rarity": face.rarity,
		"cost": face.cost,
	}


func _deserialize_dice_bag(raw_dice: Array) -> DiceBag:
	var bag := DiceBag.new()
	for d in raw_dice:
		if d is Dictionary:
			bag.add_die(_deserialize_die(d))
	return bag


func _deserialize_selected_dice(dice_bag: DiceBag, raw_indices: Variant) -> Array[Die]:
	var restored: Array[Die] = []
	if raw_indices is Array:
		for raw_index in raw_indices:
			var die := dice_bag.get_die(int(raw_index))
			if die != null:
				restored.append(die)
	return restored


func _serialize_modifiers(modifiers: Array[Modifier]) -> Array:
	var arr: Array = []
	for m in modifiers:
		arr.append(m.to_save_dict())
	return arr


func _deserialize_modifiers(raw: Variant) -> Array[Modifier]:
	var result: Array[Modifier] = []
	if raw is Array:
		for entry in raw:
			if entry is Dictionary:
				var m := Modifier.from_save_dict(entry)
				if m != null:
					result.append(m)
	return result


func _deserialize_die(raw_die: Dictionary) -> Die:
	var die_faces: Array[DiceFace] = []
	var raw_faces: Array = raw_die.get("faces", [])
	for f in raw_faces:
		if f is Dictionary and f.has("face_type"):
			die_faces.append(_deserialize_face(f))
		else:
			die_faces.append(DiceFace.make_basic(int(f)))
	var die_name_str: String = str(raw_die.get("name", "Basic Die"))
	var die_desc: String = str(raw_die.get("description", "A standard six-sided die"))
	var die_rarity: String = str(raw_die.get("rarity", "common"))
	return Die.new(die_faces, str(raw_die.get("color", "colorless")), die_name_str, die_desc, die_rarity)


func _deserialize_face(raw_face: Dictionary) -> DiceFace:
	return (
		DiceFace
		. new(
			str(raw_face.get("id", "")),
			int(raw_face.get("value", 0)),
			DiceFace.type_from_string(str(raw_face.get("face_type", "basic"))),
			float(raw_face.get("effect_value", 0.0)),
			str(raw_face.get("rarity", "common")),
			int(raw_face.get("cost", 0)),
		)
	)


func _phase_from_save_name(manager, phase_name: String) -> int:
	if phase_name == "MAP" and manager.current_run == null:
		return manager.Phase.FLEA_MARKET
	var phase_idx: int = manager.Phase.keys().find(phase_name)
	if phase_idx < 0:
		phase_idx = manager.Phase.FLEA_MARKET
	return phase_idx
