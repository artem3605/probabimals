class_name Die
extends RefCounted

var faces: Array[DiceFace] = []
var color: String = "colorless"
var die_name: String = "Basic Die"
var description: String = "A standard six-sided die"

func _init(initial_faces: Variant = null, die_color: String = "colorless",
		p_name: String = "Basic Die", p_description: String = "A standard six-sided die") -> void:
	if initial_faces == null or (initial_faces is Array and initial_faces.is_empty()):
		for v in [1, 2, 3, 4, 5, 6]:
			faces.append(DiceFace.make_basic(v))
	else:
		for f: DiceFace in initial_faces:
			faces.append(f.duplicate_face())
	color = die_color
	die_name = p_name
	description = p_description

func roll() -> DiceFace:
	return faces[randi() % faces.size()]

func roll_value() -> int:
	return roll().value

func swap_face(index: int, new_face: DiceFace) -> void:
	if index >= 0 and index < faces.size():
		faces[index] = new_face.duplicate_face()

func get_face(index: int) -> DiceFace:
	if index >= 0 and index < faces.size():
		return faces[index]
	return null

func get_face_values() -> Array[int]:
	var values: Array[int] = []
	for f in faces:
		values.append(f.value)
	return values

func duplicate_die() -> Die:
	var duped_faces: Array[DiceFace] = []
	for f in faces:
		duped_faces.append(f.duplicate_face())
	return Die.new(duped_faces, color, die_name, description)

static func from_values(values: Array[int], die_color: String = "colorless",
		p_name: String = "Basic Die", p_description: String = "A standard six-sided die") -> Die:
	var face_arr: Array[DiceFace] = []
	for v in values:
		face_arr.append(DiceFace.make_basic(v))
	return Die.new(face_arr, die_color, p_name, p_description)
