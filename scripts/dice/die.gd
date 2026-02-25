class_name Die
extends RefCounted

var faces: Array[int] = [1, 2, 3, 4, 5, 6]
var color: String = "colorless"
var die_name: String = "Basic Die"
var description: String = "A standard six-sided die"

func _init(initial_faces: Array[int] = [1, 2, 3, 4, 5, 6], die_color: String = "colorless",
		p_name: String = "Basic Die", p_description: String = "A standard six-sided die") -> void:
	faces = initial_faces.duplicate()
	color = die_color
	die_name = p_name
	description = p_description

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
	return Die.new(faces.duplicate(), color, die_name, description)
