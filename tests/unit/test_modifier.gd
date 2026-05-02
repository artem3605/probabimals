extends GutTest


func test_from_shop_item_parses_bonus_effect() -> void:
	var item := {
		"id": "steady_sum",
		"name": "Steady Sum",
		"rarity": "common",
		"params": {"effect": "bonus", "value": 2.0, "condition": "always"},
	}
	var mod := Modifier.from_shop_item(item)
	assert_not_null(mod)
	assert_eq(mod.id, "steady_sum")
	assert_eq(mod.name, "Steady Sum")
	assert_eq(mod.effect, Modifier.Effect.BONUS)
	assert_almost_eq(mod.value, 2.0, 0.001)
	assert_eq(mod.condition, "always")
	assert_eq(mod.rarity, "common")


func test_from_shop_item_parses_add_mult_effect() -> void:
	var item := {
		"id": "pair_boost",
		"name": "Pair Boost",
		"rarity": "common",
		"params": {"effect": "add_mult", "value": 1.0, "condition": "pair"},
	}
	var mod := Modifier.from_shop_item(item)
	assert_eq(mod.effect, Modifier.Effect.ADD_MULT)
	assert_eq(mod.condition, "pair")


func test_from_shop_item_parses_x_mult_effect() -> void:
	var item := {
		"id": "yahtzee_hunter",
		"name": "Yahtzee Hunter",
		"rarity": "rare",
		"params": {"effect": "x_mult", "value": 3.0, "condition": "yahtzee"},
	}
	var mod := Modifier.from_shop_item(item)
	assert_eq(mod.effect, Modifier.Effect.X_MULT)


func test_from_shop_item_defaults_missing_x_mult_value_to_neutral() -> void:
	var item := {
		"id": "legacy_x_mult",
		"name": "Legacy X Mult",
		"rarity": "rare",
		"params": {"effect": "x_mult", "condition": "yahtzee"},
	}
	var mod := Modifier.from_shop_item(item)
	assert_not_null(mod)
	assert_eq(mod.effect, Modifier.Effect.X_MULT)
	assert_almost_eq(mod.value, 1.0, 0.001)


func test_from_shop_item_parses_add_rerolls_effect() -> void:
	var item := {
		"id": "reroll_plus",
		"name": "Reroll Plus",
		"rarity": "uncommon",
		"params": {"effect": "add_rerolls", "value": 1},
	}
	var mod := Modifier.from_shop_item(item)
	assert_eq(mod.effect, Modifier.Effect.ADD_REROLLS)
	assert_almost_eq(mod.value, 1.0, 0.001)


func test_from_shop_item_defaults_missing_add_rerolls_value_to_one() -> void:
	var item := {
		"id": "legacy_reroll_plus",
		"name": "Legacy Reroll Plus",
		"rarity": "uncommon",
		"params": {"effect": "add_rerolls"},
	}
	var mod := Modifier.from_shop_item(item)
	assert_not_null(mod)
	assert_eq(mod.effect, Modifier.Effect.ADD_REROLLS)
	assert_almost_eq(mod.value, 1.0, 0.001)


func test_from_shop_item_returns_null_for_unknown_effect() -> void:
	var item := {"params": {"effect": "nonsense", "value": 1.0}}
	assert_null(Modifier.from_shop_item(item))


func test_from_shop_item_returns_null_for_empty_dict() -> void:
	assert_null(Modifier.from_shop_item({}))


func test_save_dict_round_trip() -> void:
	var original := Modifier.new("pair_boost", "Pair Boost", Modifier.Effect.ADD_MULT, 1.0, "pair", "common")
	var dict := original.to_save_dict()
	var restored := Modifier.from_save_dict(dict)
	assert_not_null(restored)
	assert_eq(restored.id, original.id)
	assert_eq(restored.name, original.name)
	assert_eq(restored.effect, original.effect)
	assert_almost_eq(restored.value, original.value, 0.001)
	assert_eq(restored.condition, original.condition)
	assert_eq(restored.rarity, original.rarity)


func test_from_save_dict_defaults_missing_x_mult_value_to_neutral() -> void:
	var restored := (
		Modifier
		. from_save_dict(
			{
				"id": "legacy_x_mult",
				"name": "Legacy X Mult",
				"effect": "x_mult",
				"condition": "yahtzee",
				"rarity": "rare",
			}
		)
	)
	assert_not_null(restored)
	assert_eq(restored.effect, Modifier.Effect.X_MULT)
	assert_almost_eq(restored.value, 1.0, 0.001)


func test_from_save_dict_returns_null_for_missing_effect() -> void:
	assert_null(Modifier.from_save_dict({}))
	assert_null(Modifier.from_save_dict({"effect": "garbage"}))


func test_applies_to_combo_returns_true_for_always_condition() -> void:
	var mod := Modifier.new("", "", Modifier.Effect.BONUS, 1.0, "always", "common")
	assert_true(mod.applies_to_combo("pair"))
	assert_true(mod.applies_to_combo("yahtzee"))
	assert_true(mod.applies_to_combo(""))


func test_applies_to_combo_returns_true_for_empty_condition() -> void:
	var mod := Modifier.new("", "", Modifier.Effect.BONUS, 1.0, "", "common")
	assert_true(mod.applies_to_combo("pair"))


func test_applies_to_combo_returns_true_when_condition_equals_combo_type() -> void:
	var mod := Modifier.new("", "", Modifier.Effect.ADD_MULT, 1.0, "pair", "common")
	assert_true(mod.applies_to_combo("pair"))


func test_applies_to_combo_returns_false_when_condition_differs_from_combo_type() -> void:
	var mod := Modifier.new("", "", Modifier.Effect.ADD_MULT, 1.0, "pair", "common")
	assert_false(mod.applies_to_combo("yahtzee"))
	assert_false(mod.applies_to_combo(""))


func test_effect_string_round_trip_for_all_values() -> void:
	for effect_name in ["bonus", "add_mult", "x_mult", "add_rerolls"]:
		var enum_val := Modifier.effect_from_string(effect_name)
		assert_ne(enum_val, -1, "effect_from_string('%s') should not be -1" % effect_name)
		assert_eq(Modifier.effect_to_string(enum_val), effect_name)


func test_effect_from_string_returns_minus_one_for_unknown() -> void:
	assert_eq(Modifier.effect_from_string("unknown"), -1)
	assert_eq(Modifier.effect_from_string(""), -1)
