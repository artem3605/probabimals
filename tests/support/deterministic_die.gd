extends Die

var _roll_sequence: Array[DiceFace] = []
var _cursor: int = 0

func _init(roll_sequence: Array[DiceFace], initial_faces: Variant = null,
		die_color: String = "colorless", p_name: String = "Test Die",
		p_description: String = "Deterministic test die") -> void:
	super._init(initial_faces, die_color, p_name, p_description)
	for face in roll_sequence:
		_roll_sequence.append(face.duplicate_face())

func roll() -> DiceFace:
	if _roll_sequence.is_empty():
		return super.roll()
	var face := _roll_sequence[_cursor % _roll_sequence.size()].duplicate_face()
	_cursor += 1
	return face

func reset_rolls() -> void:
	_cursor = 0
