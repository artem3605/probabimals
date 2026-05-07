extends GutTest

const PLAN_PATH := "res://scripts/ui/main_menu_run_result_plan.gd"

var _plan


func before_each() -> void:
	var script := ResourceLoader.load(PLAN_PATH)
	assert_not_null(script, "MainMenuRunResultPlan script should load")
	if script != null:
		_plan = script.new()


func test_victory_result_uses_victory_copy_and_total_score() -> void:
	var result: Dictionary = (
		_plan
		. build(
			{
				"victory": true,
				"round": 6,
				"total_score": 420,
				"coins": 17,
			}
		)
	)

	assert_eq(result.get("title_text", ""), "VICTORY")
	assert_eq(result.get("title_tone", ""), "victory")
	assert_eq(result.get("round_text", ""), "ROUND 6")
	assert_eq(result.get("score_text", ""), "SCORE 420")
	assert_eq(result.get("coins_text", ""), "COINS 17")
	assert_eq(result.get("button_text", ""), "CONTINUE")


func test_defeat_result_uses_defeat_copy() -> void:
	var result: Dictionary = (
		_plan
		. build(
			{
				"victory": false,
				"round": 3,
				"total_score": 12,
				"coins": 4,
			}
		)
	)

	assert_eq(result.get("title_text", ""), "DEFEAT")
	assert_eq(result.get("title_tone", ""), "defeat")
	assert_eq(result.get("round_text", ""), "ROUND 3")
	assert_eq(result.get("score_text", ""), "SCORE 12")
	assert_eq(result.get("coins_text", ""), "COINS 4")


func test_score_field_takes_precedence_over_legacy_total_score() -> void:
	var result: Dictionary = (
		_plan
		. build(
			{
				"victory": true,
				"round": 2,
				"score": 99,
				"total_score": 12,
				"coins": 8,
			}
		)
	)

	assert_eq(result.get("score_text", ""), "SCORE 99")


func test_missing_numeric_fields_default_to_zero() -> void:
	var result: Dictionary = _plan.build({"victory": false})

	assert_eq(result.get("round_text", ""), "ROUND 0")
	assert_eq(result.get("score_text", ""), "SCORE 0")
	assert_eq(result.get("coins_text", ""), "COINS 0")
