extends Node

const RunState := preload("res://scripts/map/run_state.gd")
const MapGeneratorRef := preload("res://scripts/map/map_generator.gd")
const MapNodeRef := preload("res://scripts/map/map_node.gd")

enum Phase { MAIN_MENU, FLEA_MARKET, DICE_SELECT, COMBAT, MAP }

const SAVE_PATH := "user://save_game.json"
const APP_VERSION_SETTING := "application/config/version"
const DEFAULT_APP_VERSION := "v0.0.0"
const SAVE_FORMAT_VERSION := 2
const PLAYTEST_SURVEY_URL_SETTING := "playtest/survey_url"
const STARTING_COINS: int = 10

signal phase_changed(new_phase: Phase)
signal coins_changed(new_amount: int)
signal score_changed(new_score: int)

var current_phase: Phase = Phase.MAIN_MENU
var coins: int = STARTING_COINS
var dice_bag: DiceBag = DiceBag.new()
var modifiers: Array[Modifier] = []
var total_score: int = 0
var target_score: int = 150
var hands_per_round: int = 4
var rerolls_per_hand: int = 3
var selected_dice: Array[Die] = []
var current_round: int = 1
var current_run: RunState = null
var last_run_result: Dictionary = {}
const BASE_TARGET: int = 150
var save_path: String = SAVE_PATH
var _last_tutorial_completed: bool = false
var _last_tutorial_active: bool = false
var _pending_combat_result_phase: int = -1


func _ready() -> void:
	_sync_tutorial_tracking()
	if not TutorialManager.state_changed.is_connected(_on_tutorial_state_changed):
		TutorialManager.state_changed.connect(_on_tutorial_state_changed)


func start_game(skip_tutorial_intro: bool = false) -> void:
	delete_save()
	_reset_run_state()
	current_run = MapGeneratorRef.generate(randi(), DataManager.get_map_config())
	last_run_result = {}
	if skip_tutorial_intro:
		TutorialManager.clear_active_tutorial()
	elif TutorialManager.should_auto_start_on_new_game():
		TutorialManager.start_first_run()
	else:
		TutorialManager.clear_active_tutorial()

	AudioManager.pause_for_ad()
	PokiSDK.commercial_break()
	await PokiSDK.commercial_break_done
	AudioManager.resume_after_ad()

	if TutorialManager.is_active() and TutorialManager.is_intro_step():
		_setup_intro_combat()
		_change_phase(Phase.COMBAT)
	else:
		_change_phase(Phase.MAP)


func start_tutorial_replay() -> void:
	delete_save()
	_reset_run_state()
	current_run = null
	last_run_result = {}
	TutorialManager.start_replay()
	_setup_intro_combat()
	AudioManager.pause_for_ad()
	PokiSDK.commercial_break()
	await PokiSDK.commercial_break_done
	AudioManager.resume_after_ad()
	_change_phase(Phase.COMBAT)


func skip_active_tutorial() -> void:
	if not TutorialManager.is_active():
		return
	_reset_run_state()
	current_run = MapGeneratorRef.generate(randi(), DataManager.get_map_config())
	last_run_result = {}
	TutorialManager.complete_tutorial()
	_change_phase(Phase.MAP)


func _setup_intro_combat() -> void:
	current_round = 0
	target_score = 60
	coins = 25
	selected_dice.clear()
	for die in dice_bag.get_all():
		selected_dice.append(die)


func _reset_run_state() -> void:
	clear_resolved_combat_result()
	coins = STARTING_COINS
	total_score = 0
	current_round = 1
	target_score = BASE_TARGET
	hands_per_round = 4
	rerolls_per_hand = 3
	modifiers.clear()
	dice_bag = DiceBag.new()
	for i in range(5):
		dice_bag.add_die(Die.new())
	selected_dice.clear()


func buy_item(item: Dictionary) -> bool:
	var cost: int = item.get("cost", 0)
	if coins < cost:
		return false
	var category: String = item.get("category", "")
	var modifier: Modifier = null
	if category == "modifier":
		modifier = Modifier.from_shop_item(item)
		if modifier == null:
			return false
	coins -= cost
	coins_changed.emit(coins)

	match category:
		"die":
			var params = item.get("params", {})
			var die_color: String = params.get("color", "colorless")
			var die_name_str: String = item.get("name", "Basic Die")
			var die_desc: String = item.get("description", "A standard six-sided die")
			var die_rarity: String = item.get("rarity", "common")
			if params.has("faces"):
				var int_faces: Array[int] = []
				for f in params["faces"]:
					int_faces.append(int(f))
				dice_bag.add_die(Die.from_values(int_faces, die_color, die_name_str, die_desc, die_rarity))
			else:
				dice_bag.add_die(Die.new([], die_color, die_name_str, die_desc, die_rarity))
		"face":
			pass
		"modifier":
			if modifier.effect == Modifier.Effect.ADD_REROLLS:
				rerolls_per_hand += int(modifier.value)
			else:
				modifiers.append(modifier)
	return true


func buy_face_swap(die_index: int, face_index: int, new_face: DiceFace, cost: int) -> bool:
	if coins < cost:
		return false
	coins -= cost
	coins_changed.emit(coins)
	var die := dice_bag.get_die(die_index)
	if die != null:
		die.swap_face(face_index, new_face)
	return true


func swap_face(die_index: int, face_index: int, new_face: DiceFace) -> void:
	var die := dice_bag.get_die(die_index)
	if die != null:
		die.swap_face(face_index, new_face)


func go_to_combat() -> void:
	_change_phase(Phase.COMBAT)


func go_to_flea_market() -> void:
	_change_phase(Phase.FLEA_MARKET)


func go_to_main_menu() -> void:
	_change_phase(Phase.MAIN_MENU)


func go_to_dice_select() -> void:
	_change_phase(Phase.DICE_SELECT)


func flea_market_continue() -> void:
	if current_run == null:
		_change_phase(Phase.DICE_SELECT)
		return
	var node: MapNodeRef = current_run.get_current_node()
	if node == null:
		push_warning("Unexpected Flea Market continue before selecting a map node.")
		_change_phase(Phase.MAP)
		return
	if node.type == MapNodeRef.NodeType.SHOP:
		complete_current_node()
		return
	push_warning("Unexpected Flea Market continue from non-shop map node %d." % node.id)
	_change_phase(Phase.MAP)


func end_combat(final_score: int, target_beaten: bool) -> void:
	var destination := _apply_combat_result_state(final_score, target_beaten)
	_change_phase(destination)


func resolve_combat_result_for_overlay(final_score: int, target_beaten: bool) -> Phase:
	if _pending_combat_result_phase >= 0:
		return _pending_combat_result_phase as Phase
	var destination := _apply_combat_result_state(final_score, target_beaten)
	_pending_combat_result_phase = destination
	if destination == Phase.MAIN_MENU:
		delete_save()
	else:
		save_game()
	return destination


func finish_resolved_combat_result() -> void:
	if _pending_combat_result_phase < 0:
		return
	var destination := _pending_combat_result_phase as Phase
	_pending_combat_result_phase = -1
	_change_phase(destination)


func has_resolved_combat_result() -> bool:
	return _pending_combat_result_phase >= 0


func clear_resolved_combat_result() -> void:
	_pending_combat_result_phase = -1


func _apply_combat_result_state(final_score: int, target_beaten: bool) -> Phase:
	total_score = final_score
	score_changed.emit(total_score)
	PokiSDK.gameplay_stop()
	if TutorialManager.is_active() and TutorialManager.is_intro_step():
		if target_beaten:
			_apply_round_advance()
			return Phase.FLEA_MARKET
		return Phase.MAIN_MENU
	if current_run != null:
		if current_run.current_node_id == -1:
			if target_beaten:
				return Phase.MAP
			_apply_end_run(false)
			return Phase.MAIN_MENU
		if target_beaten:
			return _apply_current_node_completion_state()
		_apply_end_run(false)
		return Phase.MAIN_MENU
	if target_beaten:
		_apply_round_advance()
		return Phase.FLEA_MARKET
	return Phase.MAIN_MENU


func _apply_round_advance() -> void:
	var reward := 10 + 5 * current_round
	coins += reward
	coins_changed.emit(coins)
	current_round += 1
	target_score = int(floor(BASE_TARGET * pow(1.5, current_round - 1)))
	selected_dice.clear()


func advance_round() -> void:
	_apply_round_advance()
	_change_phase(Phase.FLEA_MARKET)


func complete_current_node() -> void:
	var destination := _apply_current_node_completion_state()
	if destination >= 0:
		_change_phase(destination as Phase)


func _apply_current_node_completion_state() -> int:
	if current_run == null:
		push_warning("Cannot complete a map node without an active run.")
		return -1
	var node: MapNodeRef = current_run.get_current_node()
	if node == null:
		push_warning("Cannot complete a map node before one is selected.")
		return -1
	match node.type:
		MapNodeRef.NodeType.COMBAT:
			current_run.complete_current_node()
			_apply_round_advance()
			return Phase.MAP
		MapNodeRef.NodeType.SHOP:
			current_run.complete_current_node()
			return Phase.MAP
		MapNodeRef.NodeType.BOSS:
			current_run.complete_current_node()
			_apply_round_reward()
			selected_dice.clear()
			_apply_end_run(true)
			return Phase.MAIN_MENU
	return -1


func enter_map_node(node_id: int) -> void:
	if current_run == null:
		push_warning("Cannot enter a map node without an active run.")
		return
	var available := current_run.available_node_ids()
	if not available.has(node_id):
		push_warning("Cannot enter unavailable map node %d." % node_id)
		return
	current_run.enter_node(node_id)
	var node: MapNodeRef = current_run.nodes[node_id]
	if node.type == MapNodeRef.NodeType.BOSS:
		var boss_multiplier := float(DataManager.get_map_config().get("boss_blind_multiplier", 1.5))
		target_score = int(floor(float(target_score) * boss_multiplier))
	match node.type:
		MapNodeRef.NodeType.COMBAT, MapNodeRef.NodeType.BOSS:
			_change_phase(Phase.DICE_SELECT)
		MapNodeRef.NodeType.SHOP:
			_change_phase(Phase.FLEA_MARKET)


func end_run(victory: bool) -> void:
	_apply_end_run(victory)
	_change_phase(Phase.MAIN_MENU)


func _apply_end_run(victory: bool) -> void:
	last_run_result = {
		"victory": victory,
		"round": current_round,
		"total_score": total_score,
		"coins": coins,
	}
	current_run = null
	delete_save()


func abandon_run() -> void:
	clear_resolved_combat_result()
	current_run = null
	last_run_result = {}
	delete_save()


func get_round_reward() -> int:
	return 10 + 5 * current_round


func _apply_round_reward() -> void:
	coins += get_round_reward()
	coins_changed.emit(coins)


func get_app_version() -> String:
	var version := str(ProjectSettings.get_setting(APP_VERSION_SETTING, DEFAULT_APP_VERSION))
	if version.is_empty():
		return DEFAULT_APP_VERSION
	return version


func get_playtest_survey_url() -> String:
	return str(ProjectSettings.get_setting(PLAYTEST_SURVEY_URL_SETTING, "")).strip_edges()


func has_playtest_survey_url() -> bool:
	return not get_playtest_survey_url().is_empty()


func open_playtest_survey() -> bool:
	var url := get_playtest_survey_url()
	if url.is_empty():
		return false
	return OS.shell_open(url) == OK


func _change_phase(new_phase: Phase) -> void:
	var old_phase := current_phase
	current_phase = new_phase
	phase_changed.emit(new_phase)
	if new_phase != Phase.MAIN_MENU:
		save_game()
	_pending_combat_result_phase = -1

	if new_phase == Phase.MAIN_MENU and old_phase != Phase.MAIN_MENU:
		AudioManager.pause_for_ad()
		PokiSDK.commercial_break()
		await PokiSDK.commercial_break_done
		AudioManager.resume_after_ad()

	match new_phase:
		Phase.MAIN_MENU:
			get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
		Phase.FLEA_MARKET:
			get_tree().change_scene_to_file("res://scenes/flea_market/flea_market_screen.tscn")
			PokiSDK.gameplay_start()
		Phase.DICE_SELECT:
			get_tree().change_scene_to_file("res://scenes/dice_select/dice_select_screen.tscn")
		Phase.COMBAT:
			get_tree().change_scene_to_file("res://scenes/combat/combat_screen.tscn")
			PokiSDK.gameplay_start()
		Phase.MAP:
			get_tree().change_scene_to_file("res://scenes/map/map_screen.tscn")


# -- Save / Load ---------------------------------------------------------------


func has_save(path_override: String = "") -> bool:
	return FileAccess.file_exists(_resolve_save_path(path_override))


func can_load_save(path_override: String = "") -> bool:
	return not _normalize_save_data(_read_save_data(path_override)).is_empty()


func build_save_data() -> Dictionary:
	var save_phase := current_phase
	if _pending_combat_result_phase >= 0:
		save_phase = _pending_combat_result_phase as Phase
	elif not TutorialManager.is_active():
		if save_phase == Phase.COMBAT:
			save_phase = Phase.DICE_SELECT if current_run != null else Phase.FLEA_MARKET
		elif save_phase == Phase.MAP and current_run == null:
			save_phase = Phase.FLEA_MARKET

	var data := {
		"save_version": SAVE_FORMAT_VERSION,
		"app_version": get_app_version(),
		"phase": Phase.keys()[save_phase],
		"coins": coins,
		"total_score": total_score,
		"target_score": target_score,
		"hands_per_round": hands_per_round,
		"rerolls_per_hand": rerolls_per_hand,
		"current_round": current_round,
		"dice_bag": _serialize_dice_bag(),
		"selected_dice_indices": _serialize_selected_dice_indices(),
		"modifiers": _serialize_modifiers(),
		"tutorial_completed": TutorialManager.completed,
		"tutorial_mode": TutorialManager.mode,
		"tutorial_step_id": TutorialManager.step_id,
		"tutorial_state": TutorialManager.build_save_data(),
	}
	if current_run != null:
		data["current_run"] = _serialize_run_state(current_run)
	return data


func apply_save_data(data: Dictionary) -> Phase:
	var normalized := _normalize_save_data(data)
	if normalized.is_empty():
		return current_phase
	return _apply_normalized_save_data(normalized)


func _apply_normalized_save_data(data: Dictionary) -> Phase:
	clear_resolved_combat_result()
	coins = int(data.get("coins", STARTING_COINS))
	total_score = int(data.get("total_score", 0))
	target_score = int(data.get("target_score", 150))
	hands_per_round = int(data.get("hands_per_round", 4))
	rerolls_per_hand = int(data.get("rerolls_per_hand", 3))
	current_round = int(data.get("current_round", 1))
	dice_bag = _deserialize_dice_bag(data.get("dice_bag", []))
	modifiers = _deserialize_modifiers(data.get("modifiers", []))
	selected_dice = _deserialize_selected_dice(data.get("selected_dice_indices", []))
	current_run = _deserialize_run_state(data.get("current_run", {}))
	last_run_result = {}
	var tutorial_state: Dictionary = data.get("tutorial_state", {})
	if tutorial_state.is_empty():
		tutorial_state = {
			"completed": bool(data.get("tutorial_completed", false)),
			"mode": str(data.get("tutorial_mode", TutorialManager.MODE_INACTIVE)),
			"step_id": str(data.get("tutorial_step_id", "")),
		}
	TutorialManager.apply_save_data(tutorial_state)
	return _phase_from_save_name(str(data.get("phase", "FLEA_MARKET")))


func save_game(path_override: String = "") -> void:
	var file := FileAccess.open(_resolve_save_path(path_override), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(build_save_data()))


func load_game(path_override: String = "") -> void:
	var data := _read_save_data(path_override)
	var normalized := _normalize_save_data(data)
	if normalized.is_empty():
		return
	var phase_to_load := _apply_normalized_save_data(normalized)

	AudioManager.pause_for_ad()
	PokiSDK.commercial_break()
	await PokiSDK.commercial_break_done
	AudioManager.resume_after_ad()

	_change_phase(phase_to_load)


func delete_save(path_override: String = "") -> void:
	var resolved_path := _resolve_save_path(path_override)
	if FileAccess.file_exists(resolved_path):
		DirAccess.remove_absolute(resolved_path)


func _resolve_save_path(path_override: String) -> String:
	if not path_override.is_empty():
		return path_override
	return save_path


func _on_tutorial_state_changed() -> void:
	var just_completed := TutorialManager.completed and not _last_tutorial_completed
	var just_cleared_active := _last_tutorial_active and not TutorialManager.is_active()
	_sync_tutorial_tracking()
	if current_phase != Phase.MAIN_MENU and (just_completed or just_cleared_active):
		save_game()


func _sync_tutorial_tracking() -> void:
	_last_tutorial_completed = TutorialManager.completed
	_last_tutorial_active = TutorialManager.is_active()


func _read_save_data(path_override: String = "") -> Dictionary:
	var file := FileAccess.open(_resolve_save_path(path_override), FileAccess.READ)
	if not file:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return {}
	var raw: Variant = json.data
	if raw is Dictionary:
		return raw.duplicate(true)
	return {}


func _normalize_save_data(data: Dictionary) -> Dictionary:
	if data.is_empty():
		return {}
	return _migrate_save_data(data, _extract_save_version(data))


func _extract_save_version(data: Dictionary) -> int:
	if data.has("save_version"):
		return int(data.get("save_version", SAVE_FORMAT_VERSION))
	return 0


func _migrate_save_data(data: Dictionary, from_version: int) -> Dictionary:
	var migrated := data.duplicate(true)
	if from_version >= 0 and from_version < SAVE_FORMAT_VERSION:
		migrated["save_version"] = SAVE_FORMAT_VERSION
		if not migrated.has("app_version"):
			migrated["app_version"] = "legacy"
		return migrated
	if from_version == SAVE_FORMAT_VERSION:
		if not migrated.has("app_version"):
			migrated["app_version"] = get_app_version()
		return migrated
	return {}


func _serialize_dice_bag() -> Array:
	var dice_arr: Array = []
	for d in dice_bag.get_all():
		dice_arr.append(_serialize_die(d))
	return dice_arr


func _serialize_run_state(run: RunState) -> Dictionary:
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


func _deserialize_run_state(raw: Variant) -> RunState:
	if not (raw is Dictionary):
		return null
	var raw_dict: Dictionary = raw
	var raw_nodes: Variant = raw_dict.get("nodes", [])
	if not (raw_nodes is Array):
		return null
	var run := RunState.new()
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


func _serialize_selected_dice_indices() -> Array:
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


func _deserialize_selected_dice(raw_indices: Variant) -> Array[Die]:
	var restored: Array[Die] = []
	if raw_indices is Array:
		for raw_index in raw_indices:
			var die := dice_bag.get_die(int(raw_index))
			if die != null:
				restored.append(die)
	return restored


func _serialize_modifiers() -> Array:
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


func _phase_from_save_name(phase_name: String) -> Phase:
	if phase_name == "MAP" and current_run == null:
		return Phase.FLEA_MARKET
	var phase_idx := Phase.keys().find(phase_name)
	if phase_idx < 0:
		phase_idx = Phase.FLEA_MARKET
	return phase_idx as Phase
