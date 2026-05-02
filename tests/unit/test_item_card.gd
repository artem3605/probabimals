extends GutTest

const ItemCard = preload("res://scripts/ui/item_card.gd")
const ShopItemCard = preload("res://scripts/ui/shop_item_card.gd")
const DiceFacePanel = preload("res://scripts/ui/dice_face_panel.gd")
const SemanticColors = preload("res://scripts/ui/semantic_colors.gd")
const TestData = preload("res://tests/support/test_data.gd")

var _pixel_font: Font = preload("res://assets/fonts/PressStart2P-Regular.ttf")


func test_dice_card_hover_description_includes_rarity() -> void:
	var die := Die.from_values([1, 2, 3, 4, 5, 6], "gold", "Gold Die", "A shiny die")
	die.set("rarity", "rare")
	var card = ItemCard.new()
	add_child_autofree(card)

	card.setup_as_dice_item(die, _pixel_font)

	assert_eq(card.hover_rarity, "RARE")


func test_inventory_dice_hover_description_only_shows_faces() -> void:
	var die := Die.from_values([1, 2, 3, 4, 5, 6], "gold", "Gold Die", "A shiny die")
	var card = ItemCard.new()
	add_child_autofree(card)

	card.setup_as_dice_item(die, _pixel_font)

	assert_true(card.hover_description.begins_with("Faces: ("))
	assert_false(card.hover_description.contains("A shiny die"))


func test_shop_dice_hover_description_only_shows_faces() -> void:
	var item: Dictionary = TestData.find_item_by_id(TestData.load_shop_catalogue(), "loaded_die")
	var card = ShopItemCard.new()
	add_child_autofree(card)

	card.setup_as_shop_item(item, _pixel_font)

	assert_true(card.hover_description.begins_with("Faces: ("))
	assert_false(card.hover_description.contains("A die weighted toward high rolls"))


func test_shop_card_hover_description_includes_rarity_for_modifiers() -> void:
	var item: Dictionary = TestData.find_item_by_id(TestData.load_shop_catalogue(), "yahtzee_hunter")
	var card = ShopItemCard.new()
	add_child_autofree(card)

	card.setup_as_shop_item(item, _pixel_font)

	assert_eq(card.hover_rarity, "RARE")


func test_common_shop_card_uses_black_outline() -> void:
	var item: Dictionary = TestData.find_item_by_id(TestData.load_shop_catalogue(), "loaded_die")
	var card = ShopItemCard.new()
	add_child_autofree(card)

	card.setup_as_shop_item(item, _pixel_font)

	var style: StyleBoxFlat = card.main_button.get_theme_stylebox("normal")
	assert_eq(style.border_color, Color("000000"))


func test_shop_modifier_label_uses_multiplicative_color() -> void:
	var item: Dictionary = TestData.find_item_by_id(TestData.load_shop_catalogue(), "pair_boost")
	var card = ShopItemCard.new()
	add_child_autofree(card)

	card.setup_as_shop_item(item, _pixel_font)

	assert_eq(card.main_button.get_theme_color("font_color"), SemanticColors.MULTIPLICATIVE)


func test_shop_modifier_label_uses_additive_color() -> void:
	var item: Dictionary = TestData.find_item_by_id(TestData.load_shop_catalogue(), "steady_sum")
	var card = ShopItemCard.new()
	add_child_autofree(card)

	card.setup_as_shop_item(item, _pixel_font)

	assert_eq(card.main_button.get_theme_color("font_color"), SemanticColors.ADDITIVE)


func test_shop_modifier_label_uses_reroll_color() -> void:
	var item: Dictionary = TestData.find_item_by_id(TestData.load_shop_catalogue(), "reroll_plus")
	var card = ShopItemCard.new()
	add_child_autofree(card)

	card.setup_as_shop_item(item, _pixel_font)

	assert_eq(card.main_button.get_theme_color("font_color"), SemanticColors.REROLL)


func test_shop_face_label_uses_face_value_color() -> void:
	var item: Dictionary = TestData.find_item_by_id(TestData.load_shop_catalogue(), "extra_6")
	var card = ShopItemCard.new()
	add_child_autofree(card)

	card.setup_as_shop_item(item, _pixel_font)

	assert_eq(card.main_button.get_theme_color("font_color"), SemanticColors.FACE_VALUE)


func test_shop_die_pips_keep_default_dark_color() -> void:
	var item: Dictionary = TestData.find_item_by_id(TestData.load_shop_catalogue(), "loaded_die")
	var card = ShopItemCard.new()
	add_child_autofree(card)

	card.setup_as_shop_item(item, _pixel_font)

	var face_panel := _find_dice_face_panel(card.main_button)
	assert_not_null(face_panel)
	assert_eq(face_panel.get("_pip_color"), Color("1a1a1a"))


func test_inventory_die_pips_keep_default_dark_color() -> void:
	var die := Die.from_values([1, 2, 3, 4, 5, 6], "gold", "Gold Die", "A shiny die")
	var card = ItemCard.new()
	add_child_autofree(card)

	card.setup_as_dice_item(die, _pixel_font)

	var face_panel := _find_dice_face_panel(card.main_button)
	assert_not_null(face_panel)
	assert_eq(face_panel.get("_pip_color"), Color("1a1a1a"))


func _find_dice_face_panel(root: Node) -> Control:
	for child in root.get_children():
		if child.get_script() == DiceFacePanel:
			return child
		var nested := _find_dice_face_panel(child)
		if nested != null:
			return nested
	return null
