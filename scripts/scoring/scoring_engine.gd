class_name ScoringEngine
extends RefCounted

## Three-layer scoring: Total = Floor(Face_Sum × Mult × X_Mult)
##
## Modifier format:
##   { effect: "bonus",    value: float, condition: String }  -> adds to Face_Sum
##   { effect: "add_mult", value: float, condition: String }  -> adds to Mult
##   { effect: "x_mult",   value: float, condition: String }  -> multiplies X_Mult
##   { effect: "add_rerolls", value: int }                    -> utility, no scoring

func calculate_score(combo: Dictionary, rolled_faces: Array[DiceFace],
		in_combo: Array[bool], modifiers: Array) -> Dictionary:
	var combo_type: String = combo.get("type", "")
	var combo_mult: float = combo.get("combo_mult", 1.0)

	# --- Layer 1: Face_Sum ---
	var face_sum := 0.0
	for face in rolled_faces:
		face_sum += face.get_face_sum_contribution()

	for mod in modifiers:
		if mod.get("effect", "") == "bonus" and _check_condition(mod, combo_type):
			face_sum += mod.get("value", 0.0)

	# --- Layer 2: Mult (additive) ---
	var mult: float = combo_mult

	for i in range(rolled_faces.size()):
		mult += rolled_faces[i].get_add_mult()

	for mod in modifiers:
		if mod.get("effect", "") == "add_mult" and _check_condition(mod, combo_type):
			mult += mod.get("value", 0.0)

	# --- Layer 3: X_Mult (multiplicative) ---
	var x_mult := 1.0

	for i in range(rolled_faces.size()):
		x_mult *= rolled_faces[i].get_x_mult()

	for mod in modifiers:
		if mod.get("effect", "") == "x_mult" and _check_condition(mod, combo_type):
			x_mult *= mod.get("value", 1.0)

	# --- Final ---
	var total := int(floor(face_sum * mult * x_mult))

	return {
		"face_sum": face_sum,
		"mult": mult,
		"x_mult": x_mult,
		"total": total,
	}

func _check_condition(mod: Dictionary, combo_type: String) -> bool:
	var condition: String = mod.get("condition", "")
	if condition.is_empty() or condition == "always":
		return true
	return condition == combo_type
