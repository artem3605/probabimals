extends GutTest

const TestData = preload("res://tests/support/test_data.gd")

func test_draw_returns_available_dice_in_order() -> void:
	var bag := DiceBag.new()
	var die_a := TestData.die_from_values([1, 1, 1, 1, 1, 1], "red", "A")
	var die_b := TestData.die_from_values([2, 2, 2, 2, 2, 2], "green", "B")

	bag.add_die(die_a)
	bag.add_die(die_b)

	var drawn := bag.draw(5)

	assert_eq(drawn.size(), 2)
	assert_eq(drawn[0].die_name, "A")
	assert_eq(drawn[1].die_name, "B")

func test_remove_die_ignores_invalid_index() -> void:
	var bag := DiceBag.new()
	bag.add_die(TestData.die_from_values([1, 2, 3, 4, 5, 6]))

	bag.remove_die(-1)
	bag.remove_die(3)

	assert_eq(bag.size(), 1)

func test_remove_die_deletes_requested_entry() -> void:
	var bag := DiceBag.new()
	bag.add_die(TestData.die_from_values([1, 1, 1, 1, 1, 1], "red", "A"))
	bag.add_die(TestData.die_from_values([2, 2, 2, 2, 2, 2], "green", "B"))

	bag.remove_die(0)

	assert_eq(bag.size(), 1)
	assert_eq(bag.get_die(0).die_name, "B")

func test_get_die_returns_null_for_invalid_index() -> void:
	var bag := DiceBag.new()

	assert_null(bag.get_die(-1))
	assert_null(bag.get_die(0))
