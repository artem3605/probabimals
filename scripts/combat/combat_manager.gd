class_name CombatManager
extends Node

signal machine_spun(machine: Machine, results: Array, points: int)
signal combat_ended(final_score: int)

var machines: Array[Machine] = []
var running_score: int = 0
var is_combat_active: bool = false

var _scoring_engine: ScoringEngine


func start_combat() -> void:
	machines = GameManager.machines
	running_score = 0
	is_combat_active = true
	_scoring_engine = ScoringEngine.new(DataManager.get_scoring_rules())


func spin_machine(machine: Machine) -> void:
	if not is_combat_active:
		return
	if machine.spins_remaining <= 0:
		return

	var slot_machine := machine as SlotMachine
	if not slot_machine:
		return

	var results := slot_machine.spin()
	if results.is_empty():
		return

	var score_data := _scoring_engine.calculate_spin_score(results, machine)
	var points: int = score_data["total"]
	running_score += points
	GameManager.add_score(points)

	machine_spun.emit(machine, results, points)

	if _check_all_spins_exhausted():
		end_combat()


func end_combat() -> void:
	is_combat_active = false
	combat_ended.emit(running_score)


func _check_all_spins_exhausted() -> bool:
	for machine in machines:
		if machine.spins_remaining > 0:
			return false
	return true
