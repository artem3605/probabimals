class_name ShopGenerator
extends RefCounted

const DEFAULT_SHOP_SLOTS := 5
const REQUIRED_CATEGORIES := ["die", "modifier"]

var _rng := RandomNumberGenerator.new()


func set_seed(seed_value: int) -> void:
	_rng.seed = seed_value


func randomize_seed() -> void:
	_rng.randomize()


func generate_offerings(catalogue: Array, slots: int = DEFAULT_SHOP_SLOTS) -> Array[Dictionary]:
	var pool := _typed_catalogue(catalogue)
	var offerings: Array[Dictionary] = []
	if pool.is_empty() or slots <= 0:
		return offerings

	for category in REQUIRED_CATEGORIES:
		if offerings.size() >= slots:
			break
		var picked := _draw_weighted_from_category(pool, category)
		if not picked.is_empty():
			offerings.append(picked)
			_remove_item_by_id(pool, str(picked.get("id", "")))

	while offerings.size() < slots and not pool.is_empty():
		var picked := _draw_weighted(pool)
		if picked.is_empty():
			break
		offerings.append(picked)
		_remove_item_by_id(pool, str(picked.get("id", "")))

	return offerings


func _typed_catalogue(catalogue: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in catalogue:
		if item is Dictionary:
			result.append(item.duplicate(true))
	return result


func _draw_weighted_from_category(pool: Array[Dictionary], category: String) -> Dictionary:
	var category_pool: Array[Dictionary] = []
	for item in pool:
		if item.get("category", "") == category:
			category_pool.append(item)
	return _draw_weighted(category_pool)


func _draw_weighted(pool: Array[Dictionary]) -> Dictionary:
	if pool.is_empty():
		return {}
	var total_weight := 0.0
	for item in pool:
		total_weight += _item_weight(item)
	if total_weight <= 0.0:
		return pool[0].duplicate(true)

	var roll := _rng.randf_range(0.0, total_weight)
	var cursor := 0.0
	for item in pool:
		cursor += _item_weight(item)
		if roll <= cursor:
			return item.duplicate(true)
	return pool[pool.size() - 1].duplicate(true)


func _item_weight(item: Dictionary) -> float:
	return maxf(float(item.get("shop_weight", 1.0)), 0.0)


func _remove_item_by_id(pool: Array[Dictionary], item_id: String) -> void:
	for i in range(pool.size() - 1, -1, -1):
		if str(pool[i].get("id", "")) == item_id:
			pool.remove_at(i)
			return
