class_name Die
extends RefCounted

var faces: Array[int] = [1, 2, 3, 4, 5, 6]
var color: String = "colorless"

func _init(initial_faces: Array[int] = [1, 2, 3, 4, 5, 6], die_color: String = "colorless") -> void:
	faces = initial_faces.duplicate()
	color = die_color

func roll() -> int:
	return faces[randi() % faces.size()]

func swap_face(index: int, new_value: int) -> void:
	if index >= 0 and index < faces.size():
		faces[index] = new_value

func get_face(index: int) -> int:
	if index >= 0 and index < faces.size():
		return faces[index]
	return -1

func duplicate_die() -> Die:
	return Die.new(faces.duplicate(), color)
