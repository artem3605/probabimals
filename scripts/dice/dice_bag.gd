class_name DiceBag
extends RefCounted

var dice: Array[Die] = []

func add_die(die: Die) -> void:
	dice.append(die)

func remove_die(index: int) -> void:
	if index >= 0 and index < dice.size():
		dice.remove_at(index)

func draw(n: int) -> Array[Die]:
	var drawn: Array[Die] = []
	for i in range(mini(n, dice.size())):
		drawn.append(dice[i])
	return drawn

func get_all() -> Array[Die]:
	return dice

func get_die(index: int) -> Die:
	if index >= 0 and index < dice.size():
		return dice[index]
	return null

func size() -> int:
	return dice.size()
