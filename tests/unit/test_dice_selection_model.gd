extends GutTest

const DICE_SELECTION_MODEL_PATH := "res://scripts/dice/dice_selection_model.gd"
const TestData = preload("res://tests/support/test_data.gd")

var _model: Variant


func before_each() -> void:
	_model = _make_model()


func _make_model() -> Variant:
	var script: GDScript = ResourceLoader.load(DICE_SELECTION_MODEL_PATH)
	assert_not_null(script)
	if script == null:
		return null
	return script.new()


func test_build_groups_combines_matching_dice_and_preserves_bag_indices() -> void:
	var first := TestData.die_from_values([1, 2, 3, 4, 5, 6], "red", "Loaded")
	var matching := TestData.die_from_values([6, 5, 4, 3, 2, 1], "red", "Loaded Copy")
	var different := TestData.die_from_values([1, 1, 1, 1, 1, 1], "blue", "Blue")

	var dice: Array[Die] = [first, matching, different]
	var groups: Array[Dictionary] = _model.build_groups(dice)

	assert_eq(groups.size(), 2)
	assert_same(groups[0]["die"], first)
	assert_eq(groups[0]["color"], "red")
	assert_eq(groups[0]["total"], 2)
	assert_eq(groups[0]["selected"], 0)
	assert_eq(groups[0]["indices"], [0, 1])
	assert_same(groups[1]["die"], different)
	assert_eq(groups[1]["indices"], [2])


func test_increment_and_decrement_respect_group_total_and_selection_limit() -> void:
	var dice: Array[Die] = [
		TestData.die_from_values([1, 2, 3, 4, 5, 6]),
		TestData.die_from_values([1, 2, 3, 4, 5, 6]),
		TestData.die_from_values([1, 1, 1, 1, 1, 1]),
	]
	var groups: Array[Dictionary] = _model.build_groups(dice)

	assert_true(_model.increment(groups, 0, 2))
	assert_true(_model.increment(groups, 0, 2))
	assert_false(_model.increment(groups, 1, 2))
	assert_eq(_model.total_selected(groups), 2)
	assert_false(_model.increment(groups, 0, 2))
	assert_true(_model.decrement(groups, 0))
	assert_eq(groups[0]["selected"], 1)
	assert_false(_model.decrement(groups, 1))


func test_selected_indices_and_dice_follow_group_selection_order() -> void:
	var dice: Array[Die] = [
		TestData.die_from_values([1, 2, 3, 4, 5, 6], "red"),
		TestData.die_from_values([1, 1, 1, 1, 1, 1], "blue"),
		TestData.die_from_values([6, 5, 4, 3, 2, 1], "red"),
	]
	var groups: Array[Dictionary] = _model.build_groups(dice)
	groups[0]["selected"] = 2
	groups[1]["selected"] = 1

	var selected_indices: Array[int] = _model.selected_indices(groups)
	var selected_dice: Array[Die] = _model.selected_dice(groups, dice)

	assert_eq(selected_indices, [0, 2, 1])
	assert_same(selected_dice[0], dice[0])
	assert_same(selected_dice[1], dice[2])
	assert_same(selected_dice[2], dice[1])
