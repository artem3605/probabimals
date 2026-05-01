class_name ScoringEngine
extends RefCounted

## Three-layer scoring: Total = Floor(Face_Sum × Mult × X_Mult)

func calculate_score(combo: Dictionary, rolled_faces: Array[DiceFace],
		in_combo: Array[bool], modifiers: Array[Modifier]) -> Dictionary:
	var combo_type: String = combo.get("type", "")
	var combo_mult: float = combo.get("combo_mult", 1.0)

	# --- Layer 1: Face_Sum ---
	var face_sum := 0.0
	for face in rolled_faces:
		face_sum += face.get_face_sum_contribution()
	for mod in modifiers:
		if mod.effect == Modifier.Effect.BONUS and mod.applies_to_combo(combo_type):
			face_sum += mod.value

	# --- Layer 2: Mult (additive) ---
	var mult: float = combo_mult
	for face in rolled_faces:
		mult += face.get_add_mult()
	for mod in modifiers:
		if mod.effect == Modifier.Effect.ADD_MULT and mod.applies_to_combo(combo_type):
			mult += mod.value

	# --- Layer 3: X_Mult (multiplicative) ---
	var x_mult := 1.0
	for face in rolled_faces:
		x_mult *= face.get_x_mult()
	for mod in modifiers:
		if mod.effect == Modifier.Effect.X_MULT and mod.applies_to_combo(combo_type):
			x_mult *= mod.value

	var total := int(floor(face_sum * mult * x_mult))
	return {
		"face_sum": face_sum,
		"mult": mult,
		"x_mult": x_mult,
		"total": total,
	}
