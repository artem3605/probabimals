extends Node

enum Phase { MAIN_MENU, FLEA_MARKET, DICE_SELECT, COMBAT }

const SAVE_PATH := "user://save_game.json"

signal phase_changed(new_phase: Phase)
signal coins_changed(new_amount: int)
signal score_changed(new_score: int)

var current_phase: Phase = Phase.MAIN_MENU
var coins: int = 50
var dice_bag: DiceBag = DiceBag.new()
var modifiers: Array = []
var total_score: int = 0
var target_score: int = 150
var hands_per_round: int = 4
var rerolls_per_hand: int = 3
var selected_dice: Array[Die] = []
var current_round: int = 1
const BASE_TARGET: int = 150
var save_path: String = SAVE_PATH

func start_game(skip_tutorial_intro: bool = false) -> void:
	delete_save()
	_reset_run_state()
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
		_change_phase(Phase.FLEA_MARKET)


func start_tutorial_replay() -> void:
	delete_save()
	_reset_run_state()
	TutorialManager.start_replay()
	_setup_intro_combat()
	AudioManager.pause_for_ad()
	PokiSDK.commercial_break()
	await PokiSDK.commercial_break_done
	AudioManager.resume_after_ad()
	_change_phase(Phase.COMBAT)


func _setup_intro_combat() -> void:
	current_round = 0
	target_score = 60
	coins = 25
	selected_dice.clear()
	for die in dice_bag.get_all():
		selected_dice.append(die)


func _reset_run_state() -> void:
	coins = 50
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
	coins -= cost
	coins_changed.emit(coins)

	var category: String = item.get("category", "")
	match category:
		"die":
			var params = item.get("params", {})
			var die_color: String = params.get("color", "colorless")
			var die_name_str: String = item.get("name", "Basic Die")
			var die_desc: String = item.get("description", "A standard six-sided die")
			if params.has("faces"):
				var int_faces: Array[int] = []
				for f in params["faces"]:
					int_faces.append(int(f))
				dice_bag.add_die(Die.from_values(int_faces, die_color, die_name_str, die_desc))
			else:
				dice_bag.add_die(Die.new([], die_color, die_name_str, die_desc))
		"face":
			pass
		"modifier":
			var params = item.get("params", {})
			var effect: String = params.get("effect", "")
			if effect == "add_rerolls":
				rerolls_per_hand += int(params.get("value", 1))
			else:
				var mod := {
					"id": item.get("id", ""),
					"name": item.get("name", ""),
					"effect": effect,
					"value": params.get("value", 1.0),
					"condition": params.get("condition", ""),
				}
				modifiers.append(mod)
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

func end_combat(final_score: int, target_beaten: bool) -> void:
	total_score = final_score
	score_changed.emit(total_score)
	PokiSDK.gameplay_stop()
	if target_beaten:
		advance_round()
	else:
		go_to_main_menu()

func advance_round() -> void:
	var reward := 10 + 5 * current_round
	coins += reward
	coins_changed.emit(coins)
	current_round += 1
	target_score = int(floor(BASE_TARGET * pow(1.5, current_round - 1)))
	selected_dice.clear()
	_change_phase(Phase.FLEA_MARKET)

func get_round_reward() -> int:
	return 10 + 5 * current_round

func _change_phase(new_phase: Phase) -> void:
	var old_phase := current_phase
	current_phase = new_phase
	phase_changed.emit(new_phase)
	if new_phase != Phase.MAIN_MENU:
		save_game()

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


# -- Save / Load ---------------------------------------------------------------

func has_save(path_override: String = "") -> bool:
	return FileAccess.file_exists(_resolve_save_path(path_override))


func build_save_data() -> Dictionary:
	var save_phase := current_phase
	if save_phase == Phase.COMBAT and not TutorialManager.is_active():
		save_phase = Phase.FLEA_MARKET

	return {
		"phase": Phase.keys()[save_phase],
		"coins": coins,
		"total_score": total_score,
		"target_score": target_score,
		"hands_per_round": hands_per_round,
		"rerolls_per_hand": rerolls_per_hand,
		"current_round": current_round,
		"dice_bag": _serialize_dice_bag(),
		"selected_dice_indices": _serialize_selected_dice_indices(),
		"modifiers": modifiers.duplicate(true),
		"tutorial_completed": TutorialManager.completed,
		"tutorial_mode": TutorialManager.mode,
		"tutorial_step_id": TutorialManager.step_id,
		"tutorial_state": TutorialManager.build_save_data(),
	}


func apply_save_data(data: Dictionary) -> Phase:
	coins = int(data.get("coins", 50))
	total_score = int(data.get("total_score", 0))
	target_score = int(data.get("target_score", 150))
	hands_per_round = int(data.get("hands_per_round", 4))
	rerolls_per_hand = int(data.get("rerolls_per_hand", 3))
	current_round = int(data.get("current_round", 1))
	dice_bag = _deserialize_dice_bag(data.get("dice_bag", []))
	modifiers = data.get("modifiers", []).duplicate(true)
	selected_dice = _deserialize_selected_dice(data.get("selected_dice_indices", []))
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
	var file := FileAccess.open(_resolve_save_path(path_override), FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return
	var data: Dictionary = json.data
	var phase_to_load := apply_save_data(data)

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


func _serialize_dice_bag() -> Array:
	var dice_arr: Array = []
	for d in dice_bag.get_all():
		dice_arr.append(_serialize_die(d))
	return dice_arr


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
	return Die.new(die_faces, str(raw_die.get("color", "colorless")), die_name_str, die_desc)


func _deserialize_face(raw_face: Dictionary) -> DiceFace:
	return DiceFace.new(
		str(raw_face.get("id", "")),
		int(raw_face.get("value", 0)),
		DiceFace.type_from_string(str(raw_face.get("face_type", "basic"))),
		float(raw_face.get("effect_value", 0.0)),
		str(raw_face.get("rarity", "common")),
		int(raw_face.get("cost", 0)),
	)


func _phase_from_save_name(phase_name: String) -> Phase:
	var phase_idx := Phase.keys().find(phase_name)
	if phase_idx < 0:
		phase_idx = Phase.FLEA_MARKET
	return phase_idx as Phase
