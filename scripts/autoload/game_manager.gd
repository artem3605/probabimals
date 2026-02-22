extends Node

enum Phase { MAIN_MENU, FLEA_MARKET, DICE_SELECT, COMBAT }

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
var rerolls_per_hand: int = 2
var selected_dice: Array[Die] = []

func start_game() -> void:
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
			dice_bag.add_die(Die.new(faces_arr))
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
	match new_phase:
		Phase.MAIN_MENU:
			get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
		Phase.FLEA_MARKET:
			get_tree().change_scene_to_file("res://scenes/flea_market/flea_market_screen.tscn")
		Phase.DICE_SELECT:
			get_tree().change_scene_to_file("res://scenes/dice_select/dice_select_screen.tscn")
		Phase.COMBAT:
			get_tree().change_scene_to_file("res://scenes/combat/combat_screen.tscn")
