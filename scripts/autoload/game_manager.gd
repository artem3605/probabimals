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

func start_game() -> void:
	delete_save()
	coins = 50
	total_score = 0
	target_score = 150
	modifiers.clear()
	dice_bag = DiceBag.new()
	for i in range(5):
		dice_bag.add_die(Die.new())
	selected_dice.clear()
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
			var faces_arr: Array[int] = []
			var params = item.get("params", {})
			if params.has("faces"):
				for f in params["faces"]:
					faces_arr.append(int(f))
			else:
				faces_arr = [1, 2, 3, 4, 5, 6]
			var die_color: String = params.get("color", "colorless")
			dice_bag.add_die(Die.new(faces_arr, die_color))
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
					"target_combo": params.get("target_combo", "all"),
				}
				modifiers.append(mod)
	return true

func swap_face(die_index: int, face_index: int, new_value: int) -> void:
	var die := dice_bag.get_die(die_index)
	if die != null:
		die.swap_face(face_index, new_value)

func go_to_combat() -> void:
	_change_phase(Phase.COMBAT)

func go_to_flea_market() -> void:
	_change_phase(Phase.FLEA_MARKET)

func go_to_main_menu() -> void:
	_change_phase(Phase.MAIN_MENU)

func go_to_dice_select() -> void:
	_change_phase(Phase.DICE_SELECT)

func end_combat(final_score: int) -> void:
	total_score = final_score
	score_changed.emit(total_score)

func _change_phase(new_phase: Phase) -> void:
	current_phase = new_phase
	phase_changed.emit(new_phase)
	if new_phase != Phase.MAIN_MENU:
		save_game()
	match new_phase:
		Phase.MAIN_MENU:
			get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
		Phase.FLEA_MARKET:
			get_tree().change_scene_to_file("res://scenes/flea_market/flea_market_screen.tscn")
		Phase.DICE_SELECT:
			get_tree().change_scene_to_file("res://scenes/dice_select/dice_select_screen.tscn")
		Phase.COMBAT:
			get_tree().change_scene_to_file("res://scenes/combat/combat_screen.tscn")


# -- Save / Load ---------------------------------------------------------------

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> void:
	var dice_arr: Array = []
	for d in dice_bag.get_all():
		dice_arr.append({"faces": Array(d.faces), "color": d.color})

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

	dice_bag = DiceBag.new()
	var dice_arr: Array = data.get("dice_bag", [])
	for d in dice_arr:
		var faces: Array[int] = []
		for f in d.get("faces", [1, 2, 3, 4, 5, 6]):
			faces.append(int(f))
		dice_bag.add_die(Die.new(faces, str(d.get("color", "colorless"))))

	modifiers.clear()
	var mods: Array = data.get("modifiers", [])
	for m in mods:
		modifiers.append(m)

	selected_dice.clear()

	var phase_name: String = data.get("phase", "FLEA_MARKET")
	var phase_idx := Phase.keys().find(phase_name)
	if phase_idx < 0:
		phase_idx = Phase.FLEA_MARKET
	_change_phase(phase_idx as Phase)


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
