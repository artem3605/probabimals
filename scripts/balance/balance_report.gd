extends SceneTree

const BalanceSimulatorScript = preload("res://scripts/balance/balance_simulator.gd")
const SHOP_DATA_PATH := "res://resources/data/dice_shop.json"
const COMBO_DATA_PATH := "res://resources/data/combos.json"


func _init() -> void:
	var item_id := _read_arg("--modifier", "pair_boost")
	var simulations := int(_read_arg("--simulations", "1000"))
	var seed_value := int(_read_arg("--seed", "1"))
	var target_score := int(_read_arg("--target", "150"))
	var modifier_item := _find_item_by_id(_load_json_array(SHOP_DATA_PATH), item_id)

	if modifier_item.is_empty():
		push_error("Unknown modifier: %s" % item_id)
		quit(1)
		return

	var simulator = BalanceSimulatorScript.new()
	var report: Dictionary = (
		simulator
		. compare_modifier(
			{
				"dice": _basic_start_dice(),
				"combo_rules": _load_json_array(COMBO_DATA_PATH),
				"modifier_item": modifier_item,
				"simulations": simulations,
				"seed": seed_value,
				"target_score": target_score,
				"roll_policy": "score_immediately",
				"preset": "basic_start",
			}
		)
	)

	print(JSON.stringify(report, "\t"))
	quit(0)


func _read_arg(name: String, default_value: String) -> String:
	var args := OS.get_cmdline_user_args()
	for i in range(args.size()):
		if args[i] == name and i + 1 < args.size():
			return args[i + 1]
	return default_value


func _load_json_array(path: String) -> Array:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open: " + path)
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Array:
		return parsed
	return []


func _find_item_by_id(items: Array, item_id: String) -> Dictionary:
	for item in items:
		if item is Dictionary and item.get("id", "") == item_id:
			return item
	return {}


func _basic_start_dice() -> Array[Die]:
	var dice: Array[Die] = []
	for _i in range(5):
		dice.append(Die.from_values([1, 2, 3, 4, 5, 6]))
	return dice
