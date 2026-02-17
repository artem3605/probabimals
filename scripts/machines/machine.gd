class_name Machine
extends RefCounted

var id: String
var frame: PartData
var reels: Array[Reel] = []
var levers: Array[PartData] = []
var modifiers: Array[PartData] = []
var spins_remaining: int = 0


func is_complete() -> bool:
	return frame != null and reels.size() >= 3 and levers.size() >= 1


func get_total_spins() -> int:
	var total := 0
	for lever in levers:
		total += lever.params.get("spins", 1)
	return total


func reset_spins() -> void:
	spins_remaining = get_total_spins()


func get_score_multiplier() -> float:
	var mult := 1.0
	for mod in modifiers:
		if mod.type == "SCORE_MULTIPLIER":
			mult *= mod.params.get("multiplier", 1.0)
	return mult


func get_stats() -> Dictionary:
	return {
		"complete": is_complete(),
		"reels": reels.size(),
		"levers": levers.size(),
		"modifiers": modifiers.size(),
		"total_spins": get_total_spins(),
	}
