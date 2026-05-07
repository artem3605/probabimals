extends GutTest

const PLAN_PATH := "res://scripts/combat/combat_result_overlay_plan.gd"

var _plan


func before_each() -> void:
	var script := ResourceLoader.load(PLAN_PATH)
	assert_not_null(script, "CombatResultOverlayPlan script should load")
	if script != null:
		_plan = script.new()


func test_boss_victory_uses_terminal_copy_and_finish_button() -> void:
	var result: Dictionary = (
		_plan
		. build(
			420,
			true,
			{
				"is_boss": true,
				"target_score": 300,
				"reward": 35,
				"coin_icon": "[coin]",
			}
		)
	)

	assert_eq(result.get("score_text", ""), "420 PTS")
	assert_eq(result.get("message", ""), "BOSS DEFEATED!")
	assert_eq(result.get("subtitle", ""), "Final target: 300")
	assert_eq(result.get("next_text", ""), "FINISH RUN")
	assert_true(result.get("next_visible", false))
	assert_false(result.get("retry_visible", true))
	assert_false(result.get("survey_visible", true))
	assert_false(result.get("menu_visible", true))


func test_run_start_victory_routes_to_map_without_reward_display() -> void:
	var result: Dictionary = (
		_plan
		. build(
			60,
			true,
			{
				"is_run_start_map_transition": true,
				"current_round": 1,
				"target_score": 150,
				"reward": 20,
				"coin_icon": "[coin]",
			}
		)
	)

	assert_eq(result.get("subtitle", ""), "Choose your first route on the map.")
	assert_eq(result.get("next_text", ""), "VIEW MAP")
	assert_false(result.get("coins_visible", true))


func test_standard_victory_shows_round_reward_and_next_round() -> void:
	var result: Dictionary = (
		_plan
		. build(
			180,
			true,
			{
				"current_round": 3,
				"target_score": 250,
				"reward": 30,
				"coin_icon": "[coin]",
			}
		)
	)

	assert_eq(result.get("message", ""), "ROUND 3 CLEARED!")
	assert_eq(result.get("subtitle", ""), "Target: 250")
	assert_eq(result.get("coins_text", ""), "[center]+30[coin][/center]")
	assert_true(result.get("coins_visible", false))
	assert_eq(result.get("next_text", ""), "NEXT ROUND")


func test_tutorial_defeat_offers_retry_and_menu_without_survey() -> void:
	var result: Dictionary = (
		_plan
		. build(
			12,
			false,
			{
				"tutorial_active": true,
			}
		)
	)

	assert_eq(result.get("message", ""), "NOT QUITE!")
	assert_eq(result.get("tone", ""), "loss")
	assert_false(result.get("next_visible", true))
	assert_true(result.get("retry_visible", false))
	assert_false(result.get("survey_visible", true))
	assert_true(result.get("menu_visible", false))


func test_standard_defeat_shows_game_over_and_survey_option() -> void:
	var result: Dictionary = (
		_plan
		. build(
			49,
			false,
			{
				"current_round": 4,
			}
		)
	)

	assert_eq(result.get("message", ""), "GAME OVER")
	assert_eq(result.get("subtitle", ""), "Reached Round 4")
	assert_eq(result.get("next_text", ""), "NEXT ROUND")
	assert_false(result.get("next_visible", true))
	assert_false(result.get("retry_visible", true))
	assert_true(result.get("survey_visible", false))
	assert_true(result.get("menu_visible", false))
