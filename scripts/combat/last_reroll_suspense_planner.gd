class_name LastRerollSuspensePlanner
extends RefCounted

const STOP_BASE_DELAY := 0.16
const STOP_EXTRA_DELAY := 0.02
const MAX_LAST_STOP_DELAY := 0.8


func should_use(rerolls_remaining: int, held_dice: Array) -> bool:
	return rerolls_remaining == 1 and not unheld_indices(held_dice).is_empty()


func unheld_indices(held_dice: Array) -> Array[int]:
	var indices: Array[int] = []
	for i in range(held_dice.size()):
		if not bool(held_dice[i]):
			indices.append(i)
	return indices


func build_stop_delays(indices: Array) -> Array[float]:
	var delays: Array[float] = []
	for stop_index in range(indices.size()):
		var delay := float(stop_index) * STOP_BASE_DELAY
		delay += float(maxi(stop_index - 1, 0)) * STOP_EXTRA_DELAY
		delays.append(minf(delay, MAX_LAST_STOP_DELAY))
	return delays


func build_reveal_order(indices: Array[int]) -> Array[int]:
	var reveal_order := indices.duplicate()
	reveal_order.shuffle()
	return reveal_order
