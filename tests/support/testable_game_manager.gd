class_name TestableGameManager
extends "res://scripts/autoload/game_manager.gd"

var phase_history: Array[int] = []

func _change_phase(new_phase: Phase) -> void:
	current_phase = new_phase
	phase_history.append(new_phase)
	phase_changed.emit(new_phase)
