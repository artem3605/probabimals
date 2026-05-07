class_name MainMenuRunResultPlan
extends RefCounted

const TONE_VICTORY := "victory"
const TONE_DEFEAT := "defeat"


func build(result: Dictionary) -> Dictionary:
	var victory := bool(result.get("victory", false))
	var score := int(result.get("score", result.get("total_score", 0)))

	return {
		"title_text": "VICTORY" if victory else "DEFEAT",
		"title_tone": TONE_VICTORY if victory else TONE_DEFEAT,
		"round_text": "ROUND %d" % int(result.get("round", 0)),
		"score_text": "SCORE %d" % score,
		"coins_text": "COINS %d" % int(result.get("coins", 0)),
		"button_text": "CONTINUE",
	}
