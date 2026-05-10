class_name CombatResultOverlayPlan
extends RefCounted

const TONE_WIN := "win"
const TONE_LOSS := "loss"


func build(final_score: int, target_beaten: bool, context: Dictionary = {}) -> Dictionary:
	var result := {
		"score_text": "%d PTS" % final_score,
		"next_text": "NEXT ROUND",
		"next_visible": false,
		"retry_visible": false,
		"survey_visible": false,
		"menu_visible": false,
		"coins_text": "",
		"coins_visible": false,
	}

	if target_beaten:
		return _build_victory(result, context)
	return _build_defeat(result, context)


func _build_victory(result: Dictionary, context: Dictionary) -> Dictionary:
	var is_boss := bool(context.get("is_boss", false))
	var is_run_start := bool(context.get("is_run_start_map_transition", false))
	var tutorial_active := bool(context.get("tutorial_active", false))
	var tutorial_step_id := str(context.get("tutorial_step_id", ""))
	var intro_win_step_id := str(context.get("intro_win_step_id", "intro_win"))
	var current_round := int(context.get("current_round", 0))
	var target_score := int(context.get("target_score", 0))

	if is_boss:
		result["message"] = "BOSS DEFEATED!"
	elif current_round == 0:
		result["message"] = "ROUND CLEARED!"
	else:
		result["message"] = "ROUND %d CLEARED!" % current_round
	result["tone"] = TONE_WIN

	if tutorial_step_id == intro_win_step_id:
		result["subtitle"] = "Great start! Now let's head to the Shop and upgrade your dice."
	elif tutorial_active:
		result["subtitle"] = (
			"Great job! You improved your dice, held a strong pair, and turned it into a big combo. "
			+ "You've got the basics down!"
		)
	elif is_run_start:
		result["subtitle"] = "Choose your first route on the map."
	elif is_boss:
		result["subtitle"] = "Final target: %d" % target_score
	else:
		result["subtitle"] = "Target: %d" % target_score

	var reward := int(context.get("reward", 0))
	var coin_icon := str(context.get("coin_icon", ""))
	result["coins_text"] = "[center]+%d%s[/center]" % [reward, coin_icon]
	result["coins_visible"] = not is_run_start
	result["next_text"] = "VIEW MAP" if is_run_start else ("FINISH RUN" if is_boss else "NEXT ROUND")
	result["next_visible"] = true
	return result


func _build_defeat(result: Dictionary, context: Dictionary) -> Dictionary:
	var tutorial_active := bool(context.get("tutorial_active", false))
	var current_round := int(context.get("current_round", 0))
	result["tone"] = TONE_LOSS
	result["next_text"] = "NEXT ROUND"

	if tutorial_active:
		result["message"] = "NOT QUITE!"
		result["subtitle"] = "No worries -- give it another shot! The tutorial is here to help you practice."
		result["retry_visible"] = true
		result["menu_visible"] = true
		return result

	result["message"] = "GAME OVER"
	result["subtitle"] = "Reached Round %d" % current_round
	result["survey_visible"] = true
	result["menu_visible"] = true
	return result
