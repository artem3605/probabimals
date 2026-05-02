extends GutTest

const SemanticMarkup = preload("res://scripts/ui/semantic_markup.gd")

func test_format_description_replaces_word_coins_with_icon() -> void:
	var out := SemanticMarkup.format_description("Costs 15 coins")
	assert_true(out.contains("[img=18]res://assets/art/ui/coin.png[/img]"))
	assert_false(out.to_lower().contains("coins"))
	assert_true(out.contains("15"))


func test_format_description_replaces_singular_coin_with_icon() -> void:
	var out := SemanticMarkup.format_description("1 coin")
	assert_true(out.contains("[img=18]res://assets/art/ui/coin.png[/img]"))
	assert_false(out.to_lower().contains(" coin"))


func test_format_description_wraps_rarity_common() -> void:
	var out := SemanticMarkup.format_description("Some text\nCOMMON")
	assert_true(out.contains("[color=#aaaaaa]COMMON[/color]"))


func test_format_description_wraps_rarity_uncommon() -> void:
	var out := SemanticMarkup.format_description("Some text\nUNCOMMON")
	assert_true(out.contains("[color=#5dd6c2]UNCOMMON[/color]"))


func test_format_description_wraps_rarity_rare() -> void:
	var out := SemanticMarkup.format_description("Some text\nRARE")
	assert_true(out.contains("[color=#ff5dbb]RARE[/color]"))


func test_format_description_wraps_rarity_at_start() -> void:
	# Rarity-only input (no description prefix) should still be coloured.
	var out := SemanticMarkup.format_description("COMMON")
	assert_true(out.contains("[color=#aaaaaa]COMMON[/color]"))


func test_format_description_idempotent_when_already_tagged() -> void:
	var pre := "[color=#7ed957]+4 sum[/color]"
	assert_eq(SemanticMarkup.format_description(pre), pre)


func test_format_description_wraps_x_mult() -> void:
	var out := SemanticMarkup.format_description("x3 on Yahtzees")
	assert_true(out.contains("[color=#ff5a4a]x3[/color]"))


func test_format_description_wraps_plus_mult() -> void:
	var out := SemanticMarkup.format_description("+4 mult on Full Houses")
	assert_true(out.contains("[color=#ff5a4a]+4 mult[/color]"))


func test_format_description_wraps_plus_sum() -> void:
	var out := SemanticMarkup.format_description("+7 sum every hand")
	assert_true(out.contains("[color=#7ed957]+7 sum[/color]"))


func test_format_description_does_not_treat_sum_number_as_mult() -> void:
	# "+4 sum" must not be coloured orange.
	var out := SemanticMarkup.format_description("+4 sum")
	assert_false(out.contains("[color=#ff5a4a]"))
	assert_true(out.contains("[color=#7ed957]"))


func test_format_description_wraps_plus_n_reroll() -> void:
	var out := SemanticMarkup.format_description("+1 reroll per turn")
	assert_true(out.contains("[color=#c58fff]+1 reroll[/color]"))


func test_format_description_wraps_plus_n_rerolls_plural() -> void:
	var out := SemanticMarkup.format_description("+2 rerolls per turn")
	assert_true(out.contains("[color=#c58fff]+2 rerolls[/color]"))


func test_format_description_wraps_extra_digit_only() -> void:
	# Only the digit gets the FACE_VALUE color; the word "face" stays default.
	var out := SemanticMarkup.format_description("Replace a face with an extra 6")
	assert_true(out.contains("[color=#7fdfff]6[/color]"))
	# The word "face" must not be wrapped.
	assert_false(out.contains("[color=#7fdfff]face"))


func test_format_description_wraps_face_replacement_digit() -> void:
	var out := SemanticMarkup.format_description("Replace a face with a 3")
	assert_true(out.contains("[color=#7fdfff]3[/color]"))


func test_format_description_wraps_known_combos() -> void:
	# When the priority panel has not been built we expect the static
	# fallback color from SemanticColors.COMBO_FALLBACK_HEX.
	var out := SemanticMarkup.format_description("+4 mult on Full Houses")
	# Full house fallback color = "#7fb6ff"
	assert_true(out.contains("[color=#7fb6ff]Full House"))


func test_format_description_wraps_yahtzee() -> void:
	var out := SemanticMarkup.format_description("x3 on Yahtzees")
	assert_true(out.contains("[color=#ff7eb6]Yahtzee"))


func test_format_description_does_not_double_wrap_three_same() -> void:
	# "Three Same" must be wrapped before any digit-rule could touch it.
	var out := SemanticMarkup.format_description("+1 mult on Three Same")
	# Three same fallback color = "#7fb6ff"
	assert_true(out.contains("[color=#7fb6ff]Three Same"))
	# And the +1 mult wrap remains.
	assert_true(out.contains("[color=#ff5a4a]+1 mult[/color]"))


func test_format_face_value_wraps_digit() -> void:
	assert_eq(SemanticMarkup.format_face_value(6), "[color=#7fdfff]6[/color]")


func test_format_faces_list_wraps_each_digit() -> void:
	var out := SemanticMarkup.format_faces_list([1, 5, 6])
	assert_eq(out, "[color=#7fdfff]1[/color],[color=#7fdfff]5[/color],[color=#7fdfff]6[/color]")


func test_format_cost_outputs_icon_then_number() -> void:
	var out := SemanticMarkup.format_cost(15)
	assert_true(out.contains("[img=18]res://assets/art/ui/coin.png[/img]"))
	assert_true(out.contains("15"))


func test_format_description_preserves_existing_coin_image_bbcode() -> void:
	var pre := SemanticMarkup.format_cost(15)
	assert_eq(SemanticMarkup.format_description(pre), pre)


func test_coin_icon_returns_bbcode() -> void:
	assert_eq(SemanticMarkup.coin_icon(), "[img=18]res://assets/art/ui/coin.png[/img]")
