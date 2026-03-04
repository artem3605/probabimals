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

func start_game() -> void:
	delete_save()
	coins = 50
	total_score = 0
	current_round = 1
	target_score = BASE_TARGET
	modifiers.clear()
	dice_bag = DiceBag.new()
	for i in range(5):
		dice_bag.add_die(Die.new())
	selected_dice.clear()
	PokiSDK.commercial_break()
	await PokiSDK.commercial_break_done
	_change_phase(Phase.FLEA_MARKET)

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
		PokiSDK.commercial_break()
		await PokiSDK.commercial_break_done

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

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var dice_arr: Array = []
	for d in dice_bag.get_all():
		var face_data: Array = []
		for f in d.faces:
			face_data.append({
				"id": f.id, "value": f.value,
				"face_type": DiceFace.Type.keys()[f.face_type].to_lower(),
				"effect_value": f.effect_value,
				"rarity": f.rarity, "cost": f.cost,
			})
		dice_arr.append({
			"faces": face_data, "color": d.color,
			"name": d.die_name, "description": d.description,
		})

	var save_phase := current_phase
	if save_phase == Phase.COMBAT:
		save_phase = Phase.FLEA_MARKET

	var data := {
		"phase": Phase.keys()[save_phase],
		"coins": coins,
		"total_score": total_score,
		"target_score": target_score,
		"hands_per_round": hands_per_round,
		"rerolls_per_hand": rerolls_per_hand,
		"current_round": current_round,
		"dice_bag": dice_arr,
		"modifiers": modifiers,
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))


func load_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return
	var data: Dictionary = json.data

	coins = int(data.get("coins", 50))
	total_score = int(data.get("total_score", 0))
	target_score = int(data.get("target_score", 150))
	hands_per_round = int(data.get("hands_per_round", 4))
	rerolls_per_hand = int(data.get("rerolls_per_hand", 3))
	current_round = int(data.get("current_round", 1))

	dice_bag = DiceBag.new()
	var dice_arr: Array = data.get("dice_bag", [])
	for d in dice_arr:
		var die_faces: Array[DiceFace] = []
		var raw_faces: Array = d.get("faces", [])
		for f in raw_faces:
			if f is Dictionary and f.has("face_type"):
				die_faces.append(DiceFace.new(
					str(f.get("id", "")),
					int(f.get("value", 0)),
					DiceFace.type_from_string(str(f.get("face_type", "basic"))),
					float(f.get("effect_value", 0.0)),
					str(f.get("rarity", "common")),
					int(f.get("cost", 0)),
				))
			else:
				die_faces.append(DiceFace.make_basic(int(f)))
		var die_name_str: String = str(d.get("name", "Basic Die"))
		var die_desc: String = str(d.get("description", "A standard six-sided die"))
		dice_bag.add_die(Die.new(die_faces, str(d.get("color", "colorless")), die_name_str, die_desc))

	modifiers.clear()
	var mods: Array = data.get("modifiers", [])
	for m in mods:
		modifiers.append(m)

	selected_dice.clear()

	PokiSDK.commercial_break()
	await PokiSDK.commercial_break_done

	var phase_name: String = data.get("phase", "FLEA_MARKET")
	var phase_idx := Phase.keys().find(phase_name)
	if phase_idx < 0:
		phase_idx = Phase.FLEA_MARKET
	_change_phase(phase_idx as Phase)


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
