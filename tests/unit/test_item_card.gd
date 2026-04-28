extends GutTest

const ItemCard = preload("res://scripts/ui/item_card.gd")
const ShopItemCard = preload("res://scripts/ui/shop_item_card.gd")
const TestData = preload("res://tests/support/test_data.gd")

var _pixel_font: Font = preload("res://assets/fonts/PressStart2P-Regular.ttf")

func test_dice_card_hover_description_includes_rarity_and_enables_animation() -> void:
	var die := Die.from_values([1, 2, 3, 4, 5, 6], "gold", "Gold Die", "A shiny die")
	die.set("rarity", "rare")
	var card = ItemCard.new()
	add_child_autofree(card)

	card.setup_as_dice_item(die, _pixel_font)

	assert_true(card.hover_description.contains("RARITY: RARE"))
	assert_true(card.has_method("is_rarity_animation_active"))
	assert_true(bool(card.call("is_rarity_animation_active")))

func test_shop_card_hover_description_includes_rarity_for_modifiers() -> void:
	var item: Dictionary = TestData.find_item_by_id(TestData.load_shop_catalogue(), "yahtzee_hunter")
	var card = ShopItemCard.new()
	add_child_autofree(card)

	card.setup_as_shop_item(item, _pixel_font)

	assert_true(card.hover_description.contains("RARITY: RARE"))
	assert_true(card.has_method("is_rarity_animation_active"))
	assert_true(bool(card.call("is_rarity_animation_active")))

func test_common_shop_card_uses_black_outline() -> void:
	var item: Dictionary = TestData.find_item_by_id(TestData.load_shop_catalogue(), "red_die")
	var card = ShopItemCard.new()
	add_child_autofree(card)

	card.setup_as_shop_item(item, _pixel_font)

	var style: StyleBoxFlat = card.main_button.get_theme_stylebox("normal")
	assert_eq(style.border_color, Color("000000"))
