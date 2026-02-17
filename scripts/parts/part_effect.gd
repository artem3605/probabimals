class_name PartEffect
extends RefCounted


static func apply(part: PartData, machine: Machine) -> void:
	match part.type:
		"ADD_SYMBOL":
			var symbol_id: String = part.params.get("symbol", "")
			var weight: int = part.params.get("weight", 0)
			for reel in machine.reels:
				reel.add_symbol(symbol_id, weight)
		"CHANGE_WEIGHT":
			var symbol_id: String = part.params.get("symbol", "")
			var multiplier: float = part.params.get("multiplier", 1.0)
			for reel in machine.reels:
				reel.modify_weight(symbol_id, multiplier)
		"SCORE_MULTIPLIER":
			pass  # Read directly from part data at scoring time


static func remove(part: PartData, machine: Machine) -> void:
	match part.type:
		"ADD_SYMBOL":
			var symbol_id: String = part.params.get("symbol", "")
			var weight: int = part.params.get("weight", 0)
			for reel in machine.reels:
				reel.add_symbol(symbol_id, -weight)
		"CHANGE_WEIGHT":
			var symbol_id: String = part.params.get("symbol", "")
			var multiplier: float = part.params.get("multiplier", 1.0)
			if multiplier != 0.0:
				for reel in machine.reels:
					reel.modify_weight(symbol_id, 1.0 / multiplier)
