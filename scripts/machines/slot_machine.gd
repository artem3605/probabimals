class_name SlotMachine
extends Machine


func spin() -> Array[String]:
	if spins_remaining <= 0:
		return []
	if not is_complete():
		return []

	var results: Array[String] = []
	for reel in reels:
		results.append(reel.spin())
	spins_remaining -= 1
	return results
