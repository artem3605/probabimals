extends Node

signal phase_changed(phase: int)
signal coins_changed(amount: int)
signal score_changed(total: int)

enum Phase { MAIN_MENU, FLEA_MARKET, COMBAT }

var current_phase: Phase = Phase.MAIN_MENU
var coins: int = 50
var hand: Array[PartData] = []
var machines: Array[Machine] = []
var total_score: int = 0

const STARTING_COINS := 50


func start_game() -> void:
	coins = STARTING_COINS
	hand.clear()
	machines.clear()
	total_score = 0
	coins_changed.emit(coins)
	score_changed.emit(total_score)
	go_to_phase(Phase.FLEA_MARKET)


func go_to_phase(phase: Phase) -> void:
	current_phase = phase
	phase_changed.emit(phase)
	match phase:
		Phase.MAIN_MENU:
			get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
		Phase.FLEA_MARKET:
			get_tree().change_scene_to_file("res://scenes/flea_market/flea_market_screen.tscn")
		Phase.COMBAT:
			get_tree().change_scene_to_file("res://scenes/combat/combat_screen.tscn")


func go_to_combat() -> void:
	for machine in machines:
		machine.reset_spins()
	go_to_phase(Phase.COMBAT)


func end_combat() -> void:
	go_to_phase(Phase.MAIN_MENU)


func buy_part(part: PartData) -> bool:
	if coins >= part.cost:
		coins -= part.cost
		hand.append(part)
		coins_changed.emit(coins)
		return true
	return false


func add_score(points: int) -> void:
	total_score += points
	score_changed.emit(total_score)


func create_machine(frame: PartData) -> Machine:
	var machine := SlotMachine.new()
	machine.id = "machine_%d" % (machines.size() + 1)
	machine.frame = frame
	machines.append(machine)
	return machine


func attach_part_to_machine(part: PartData, machine: Machine) -> bool:
	match part.type:
		"REEL":
			if machine.reels.size() >= 3:
				return false
			var reel := Reel.new()
			var symbols := DataManager.get_all_symbols()
			for symbol in symbols:
				reel.base_symbol_weights[symbol["id"]] = symbol["weight"]
			machine.reels.append(reel)
			return true
		"LEVER":
			machine.levers.append(part)
			return true
		"ADD_SYMBOL", "CHANGE_WEIGHT", "SCORE_MULTIPLIER":
			machine.modifiers.append(part)
			PartEffect.apply(part, machine)
			return true
	return false


func remove_part_from_hand(part: PartData) -> void:
	for i in range(hand.size()):
		if hand[i].id == part.id:
			hand.remove_at(i)
			return


func has_complete_machine() -> bool:
	for machine in machines:
		if machine.is_complete():
			return true
	return false
