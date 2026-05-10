# Map Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a 4th top-level screen — Map — that turns existing Shop and Combat screens into nodes of a single roguelike run, ending in a Boss combat.

**Architecture:** New `Phase.MAP` and `current_run` field on `GameManager`. New screens/scripts: `MapScreen`, `MapNodeButton`, `RunState`, `MapGenerator`, `MapNode`. Existing `advance_round()`, `end_combat()`, and `Shop` "Combat" button become run-aware: they consult `current_run` to decide whether to transition to `Phase.MAP` or fall through to legacy single-round flow. `current_run` is in-memory only — not serialized into save data. Reuses existing `current_round` for blind progression rather than introducing a parallel counter.

**Tech Stack:** Godot 4.6, GDScript, GUT for tests, JSON config under `resources/data/`.

**Spec:** `docs/plans/2026-05-03-map-screen-design.md` (read this first; the addendum at the end takes precedence over the original sections where they overlap).

---

## File Structure

### New files

```
resources/data/
  map_config.json                       # depth, node count bounds, shop probability, max consecutive shops, boss multiplier

scripts/map/
  map_node.gd                           # RefCounted: { id, type, depth, next_ids }
  run_state.gd                          # RefCounted: { nodes, current_node_id, seed, available_node_ids() }
  map_generator.gd                      # RefCounted: generate(seed, config) -> RunState

scenes/map/
  map_node_button.tscn                  # one node button (icon + state)
  map_node_button.gd
  map_screen.tscn                       # map screen root
  map_screen.gd                         # renders nodes/edges, forwards clicks

tests/unit/
  test_map_node.gd
  test_run_state.gd
  test_map_generator.gd

tests/integration/
  test_run_flow.gd

tests/smoke/
  test_map_screen_smoke.gd
```

### Modified files

```
scripts/autoload/game_manager.gd        # Phase.MAP, current_run, last_run_result; route-aware end_combat / advance_round; new methods enter_map_node, complete_current_node, end_run, abandon_run
scripts/autoload/data_manager.gd        # load + validate map_config.json
scenes/main_menu/main_menu.gd           # show ResultsOverlay if last_run_result is set
scenes/combat/combat_screen.gd          # surface "back to menu" affordance as abandon_run when in a run (no other code change — end_combat dispatch is in GameManager)
scenes/shop/shop_screen.gd # rename Combat button to Continue and route through complete_current_node when in a SHOP map node
project.godot                           # nothing to change (no new autoload); GameManager already exists
```

### Module boundaries (recap)

- `MapNode`, `RunState` — pure data containers; no side effects.
- `MapGenerator.generate(seed, config)` — pure function; no globals, no autoloads.
- `MapScreen` — UI; reads `GameManager.current_run`, routes clicks back to `GameManager.enter_map_node(id)`.
- `GameManager` — orchestrator; owns `current_run` and `last_run_result`; performs phase transitions.

### `Phase` enum after this slice

```gdscript
enum Phase { MAIN_MENU, SHOP, DICE_SELECT, COMBAT, MAP }
```

`MAP` is appended at the end so existing save files (which serialize phase by name via `Phase.keys()[…]`) continue to deserialize without ambiguity. Saves never contain `MAP` (we don't persist runs).

---

## Task 1: Create the `MapNode` data class

**Files:**
- Create: `scripts/map/map_node.gd`
- Test: `tests/unit/test_map_node.gd`

- [ ] **Step 1: Write the failing test**

Create `tests/unit/test_map_node.gd`:

```gdscript
extends GutTest

const MapNode := preload("res://scripts/map/map_node.gd")


func test_constructs_with_fields() -> void:
	var node := MapNode.new(7, MapNode.NodeType.COMBAT, 3, [9, 10] as Array[int])
	assert_eq(node.id, 7)
	assert_eq(node.type, MapNode.NodeType.COMBAT)
	assert_eq(node.depth, 3)
	assert_eq(node.next_ids, [9, 10] as Array[int])


func test_node_type_values_distinct() -> void:
	assert_ne(MapNode.NodeType.COMBAT, MapNode.NodeType.SHOP)
	assert_ne(MapNode.NodeType.COMBAT, MapNode.NodeType.BOSS)
	assert_ne(MapNode.NodeType.SHOP, MapNode.NodeType.BOSS)


func test_default_next_ids_is_empty() -> void:
	var node := MapNode.new(1, MapNode.NodeType.SHOP, 1)
	assert_eq(node.next_ids.size(), 0)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `make test`
Expected: build error — `scripts/map/map_node.gd` does not exist.

- [ ] **Step 3: Write minimal implementation**

Create `scripts/map/map_node.gd`:

```gdscript
extends RefCounted
class_name MapNode

enum NodeType { COMBAT, SHOP, BOSS }

var id: int = -1
var type: NodeType = NodeType.COMBAT
var depth: int = 0
var next_ids: Array[int] = []


func _init(p_id: int = -1, p_type: NodeType = NodeType.COMBAT, p_depth: int = 0, p_next_ids: Array[int] = [] as Array[int]) -> void:
	id = p_id
	type = p_type
	depth = p_depth
	next_ids = p_next_ids.duplicate()
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `make test`
Expected: all unit tests pass, including the three new ones.

- [ ] **Step 5: Commit**

```bash
git add scripts/map/map_node.gd tests/unit/test_map_node.gd
git commit -m "feat(map): add MapNode data class"
```

---

## Task 2: Create `RunState` with `available_node_ids()`

**Files:**
- Create: `scripts/map/run_state.gd`
- Test: `tests/unit/test_run_state.gd`

- [ ] **Step 1: Write the failing test**

Create `tests/unit/test_run_state.gd`:

```gdscript
extends GutTest

const MapNode := preload("res://scripts/map/map_node.gd")
const RunState := preload("res://scripts/map/run_state.gd")


func _build_state() -> RunState:
	# 3 levels: 1 -> 2 (two nodes) -> boss
	var n1 := MapNode.new(1, MapNode.NodeType.COMBAT, 1, [2, 3] as Array[int])
	var n2 := MapNode.new(2, MapNode.NodeType.COMBAT, 2, [4] as Array[int])
	var n3 := MapNode.new(3, MapNode.NodeType.SHOP, 2, [4] as Array[int])
	var n4 := MapNode.new(4, MapNode.NodeType.BOSS, 3, [] as Array[int])
	var state := RunState.new()
	state.nodes = {1: n1, 2: n2, 3: n3, 4: n4}
	state.current_node_id = -1
	state.seed = 42
	return state


func test_available_at_start_returns_level_one_nodes() -> void:
	var state := _build_state()
	var ids := state.available_node_ids()
	ids.sort()
	assert_eq(ids, [1] as Array[int])


func test_available_after_entering_node_returns_next_ids() -> void:
	var state := _build_state()
	state.current_node_id = 1
	var ids := state.available_node_ids()
	ids.sort()
	assert_eq(ids, [2, 3] as Array[int])


func test_available_at_boss_returns_empty() -> void:
	var state := _build_state()
	state.current_node_id = 4
	assert_eq(state.available_node_ids().size(), 0)


func test_get_current_node_returns_null_at_start() -> void:
	var state := _build_state()
	assert_null(state.get_current_node())


func test_get_current_node_returns_node_after_entering() -> void:
	var state := _build_state()
	state.current_node_id = 2
	var node := state.get_current_node()
	assert_not_null(node)
	assert_eq(node.id, 2)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `make test`
Expected: build error — `scripts/map/run_state.gd` does not exist.

- [ ] **Step 3: Write minimal implementation**

Create `scripts/map/run_state.gd`:

```gdscript
extends RefCounted
class_name RunState

var nodes: Dictionary = {}     # int -> MapNode
var current_node_id: int = -1  # -1 means no node entered yet
var seed: int = 0


func get_current_node() -> MapNode:
	if current_node_id == -1:
		return null
	return nodes.get(current_node_id, null)


func available_node_ids() -> Array[int]:
	var result: Array[int] = []
	if current_node_id == -1:
		for id_key in nodes.keys():
			var node: MapNode = nodes[id_key]
			if node.depth == 1:
				result.append(node.id)
		return result
	var current: MapNode = nodes.get(current_node_id, null)
	if current == null:
		return result
	for next_id in current.next_ids:
		result.append(int(next_id))
	return result
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `make test`
Expected: all `test_run_state.gd` cases pass.

- [ ] **Step 5: Commit**

```bash
git add scripts/map/run_state.gd tests/unit/test_run_state.gd
git commit -m "feat(map): add RunState with available_node_ids"
```

---

## Task 3: Add `map_config.json` and load it via `DataManager`

**Files:**
- Create: `resources/data/map_config.json`
- Modify: `scripts/autoload/data_manager.gd`
- Test: `tests/unit/test_map_generator.gd` (a small loader smoke check; full generator tests come later)

- [ ] **Step 1: Write the failing test**

Create `tests/unit/test_map_generator.gd` (we'll grow this in Task 4):

```gdscript
extends GutTest


func test_data_manager_exposes_map_config() -> void:
	var cfg := DataManager.get_map_config()
	assert_true(cfg is Dictionary)
	assert_true(cfg.has("depth"))
	assert_true(cfg.has("min_nodes_per_level"))
	assert_true(cfg.has("max_nodes_per_level"))
	assert_true(cfg.has("shop_probability"))
	assert_true(cfg.has("max_consecutive_shops"))
	assert_true(cfg.has("boss_blind_multiplier"))


func test_map_config_values_are_sane() -> void:
	var cfg := DataManager.get_map_config()
	assert_true(int(cfg["depth"]) >= 2)
	assert_true(int(cfg["min_nodes_per_level"]) >= 1)
	assert_true(int(cfg["max_nodes_per_level"]) >= int(cfg["min_nodes_per_level"]))
	var shop_prob := float(cfg["shop_probability"])
	assert_true(shop_prob >= 0.0 and shop_prob <= 1.0)
	assert_true(int(cfg["max_consecutive_shops"]) >= 0)
	assert_true(float(cfg["boss_blind_multiplier"]) >= 1.0)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `make test`
Expected: failure — `DataManager` has no `get_map_config()` method, or returns null.

- [ ] **Step 3: Write the JSON config**

Create `resources/data/map_config.json`:

```json
{
  "depth": 6,
  "min_nodes_per_level": 1,
  "max_nodes_per_level": 3,
  "shop_probability": 0.3,
  "max_consecutive_shops": 2,
  "boss_blind_multiplier": 1.5
}
```

- [ ] **Step 4: Add the loader and validator to `DataManager`**

Edit `scripts/autoload/data_manager.gd`. Add a private field, default constants, validator, getter, and call the loader in `_ready`.

Add at the top of the file (after `var _combo_rules: Array = []`):

```gdscript
var _map_config: Dictionary = {}

const MAP_CONFIG_DEFAULTS := {
	"depth": 6,
	"min_nodes_per_level": 1,
	"max_nodes_per_level": 3,
	"shop_probability": 0.3,
	"max_consecutive_shops": 2,
	"boss_blind_multiplier": 1.5,
}
```

Update `_ready()` to also load the map config:

```gdscript
func _ready() -> void:
	_load_faces()
	_load_shop_catalogue()
	_load_combo_rules()
	_load_map_config()
```

Add new methods at the end of the file:

```gdscript
func _load_map_config() -> void:
	var data = _load_json("res://resources/data/map_config.json")
	if data is Dictionary:
		_map_config = _validated_map_config(data)
	else:
		push_error("map_config.json missing or malformed; using defaults")
		_map_config = MAP_CONFIG_DEFAULTS.duplicate()


func _validated_map_config(raw: Dictionary) -> Dictionary:
	var cfg := MAP_CONFIG_DEFAULTS.duplicate()
	for key in MAP_CONFIG_DEFAULTS.keys():
		if raw.has(key):
			cfg[key] = raw[key]
	if int(cfg["depth"]) < 2:
		push_error("map_config.depth must be >= 2; using default")
		cfg["depth"] = MAP_CONFIG_DEFAULTS["depth"]
	if int(cfg["min_nodes_per_level"]) < 1:
		push_error("map_config.min_nodes_per_level must be >= 1; using default")
		cfg["min_nodes_per_level"] = MAP_CONFIG_DEFAULTS["min_nodes_per_level"]
	if int(cfg["max_nodes_per_level"]) < int(cfg["min_nodes_per_level"]):
		push_error("map_config.max_nodes_per_level must be >= min_nodes_per_level; using default")
		cfg["max_nodes_per_level"] = MAP_CONFIG_DEFAULTS["max_nodes_per_level"]
	var shop_prob := float(cfg["shop_probability"])
	if shop_prob < 0.0 or shop_prob > 1.0:
		push_error("map_config.shop_probability must be in [0,1]; using default")
		cfg["shop_probability"] = MAP_CONFIG_DEFAULTS["shop_probability"]
	if int(cfg["max_consecutive_shops"]) < 0:
		push_error("map_config.max_consecutive_shops must be >= 0; using default")
		cfg["max_consecutive_shops"] = MAP_CONFIG_DEFAULTS["max_consecutive_shops"]
	if float(cfg["boss_blind_multiplier"]) < 1.0:
		push_error("map_config.boss_blind_multiplier must be >= 1.0; using default")
		cfg["boss_blind_multiplier"] = MAP_CONFIG_DEFAULTS["boss_blind_multiplier"]
	return cfg


func get_map_config() -> Dictionary:
	return _map_config.duplicate()
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `make test`
Expected: `test_data_manager_exposes_map_config` and `test_map_config_values_are_sane` pass.

- [ ] **Step 6: Commit**

```bash
git add resources/data/map_config.json scripts/autoload/data_manager.gd tests/unit/test_map_generator.gd
git commit -m "feat(map): add map_config.json with DataManager loader and validation"
```

---

## Task 4: Implement `MapGenerator` — basic shape

**Files:**
- Create: `scripts/map/map_generator.gd`
- Test: extend `tests/unit/test_map_generator.gd`

- [ ] **Step 1: Write the failing tests**

Append to `tests/unit/test_map_generator.gd`:

```gdscript
const MapGenerator := preload("res://scripts/map/map_generator.gd")
const MapNode2 := preload("res://scripts/map/map_node.gd")


func _gen() -> Variant:
	return MapGenerator.generate(12345, DataManager.get_map_config())


func test_generate_returns_run_state() -> void:
	var state = _gen()
	assert_not_null(state)
	assert_eq(state.current_node_id, -1)
	assert_eq(state.seed, 12345)


func test_levels_match_depth() -> void:
	var cfg := DataManager.get_map_config()
	var state = MapGenerator.generate(1, cfg)
	var depth: int = int(cfg["depth"])
	var counts := {}
	for id_key in state.nodes.keys():
		var node: MapNode2 = state.nodes[id_key]
		counts[node.depth] = int(counts.get(node.depth, 0)) + 1
	for d in range(1, depth + 1):
		assert_true(counts.has(d), "missing nodes at depth %d" % d)
		assert_true(int(counts[d]) >= 1, "no nodes at depth %d" % d)


func test_boss_is_unique_at_max_depth() -> void:
	var cfg := DataManager.get_map_config()
	var state = MapGenerator.generate(2, cfg)
	var depth: int = int(cfg["depth"])
	var boss_count := 0
	for id_key in state.nodes.keys():
		var node: MapNode2 = state.nodes[id_key]
		if node.type == MapNode2.NodeType.BOSS:
			boss_count += 1
			assert_eq(node.depth, depth)
			assert_eq(node.next_ids.size(), 0)
	assert_eq(boss_count, 1)


func test_non_boss_nodes_have_outgoing_edges() -> void:
	var cfg := DataManager.get_map_config()
	var state = MapGenerator.generate(3, cfg)
	for id_key in state.nodes.keys():
		var node: MapNode2 = state.nodes[id_key]
		if node.type != MapNode2.NodeType.BOSS:
			assert_true(node.next_ids.size() >= 1, "node %d has no next_ids" % node.id)


func test_all_nodes_reachable_from_start() -> void:
	var cfg := DataManager.get_map_config()
	var state = MapGenerator.generate(4, cfg)
	# BFS from any depth-1 node, should cover every node id.
	var visited := {}
	var queue: Array[int] = []
	for id_key in state.nodes.keys():
		var node: MapNode2 = state.nodes[id_key]
		if node.depth == 1:
			queue.append(node.id)
			visited[node.id] = true
	while not queue.is_empty():
		var cur: int = queue.pop_front()
		var n: MapNode2 = state.nodes[cur]
		for next_id in n.next_ids:
			if not visited.has(int(next_id)):
				visited[int(next_id)] = true
				queue.append(int(next_id))
	assert_eq(visited.size(), state.nodes.size())


func test_determinism_same_seed_same_map() -> void:
	var cfg := DataManager.get_map_config()
	var a = MapGenerator.generate(777, cfg)
	var b = MapGenerator.generate(777, cfg)
	assert_eq(a.nodes.size(), b.nodes.size())
	for id_key in a.nodes.keys():
		assert_true(b.nodes.has(id_key))
		var na: MapNode2 = a.nodes[id_key]
		var nb: MapNode2 = b.nodes[id_key]
		assert_eq(na.type, nb.type)
		assert_eq(na.depth, nb.depth)
		var na_next := na.next_ids.duplicate()
		var nb_next := nb.next_ids.duplicate()
		na_next.sort()
		nb_next.sort()
		assert_eq(na_next, nb_next)
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `make test`
Expected: build error or failures — `MapGenerator` does not exist.

- [ ] **Step 3: Write the generator**

Create `scripts/map/map_generator.gd`:

```gdscript
extends RefCounted
class_name MapGenerator

const MapNodeRef := preload("res://scripts/map/map_node.gd")
const RunStateRef := preload("res://scripts/map/run_state.gd")


static func generate(p_seed: int, config: Dictionary) -> RunStateRef:
	var rng := RandomNumberGenerator.new()
	rng.seed = p_seed

	var depth: int = int(config["depth"])
	var min_nodes: int = int(config["min_nodes_per_level"])
	var max_nodes: int = int(config["max_nodes_per_level"])
	var shop_prob: float = float(config["shop_probability"])
	var max_shops: int = int(config["max_consecutive_shops"])

	var levels: Array = []  # Array[Array[MapNodeRef]]
	var next_id := 1

	# Levels 1..depth-1: random count and types
	for d in range(1, depth):
		var count: int = rng.randi_range(min_nodes, max_nodes)
		var level: Array = []
		for _i in range(count):
			var t := MapNodeRef.NodeType.COMBAT
			if rng.randf() < shop_prob:
				t = MapNodeRef.NodeType.SHOP
			level.append(MapNodeRef.new(next_id, t, d))
			next_id += 1
		levels.append(level)

	# Level depth: single boss
	var boss := MapNodeRef.new(next_id, MapNodeRef.NodeType.BOSS, depth)
	next_id += 1
	levels.append([boss])

	_connect_levels(levels, rng)
	_enforce_max_consecutive_shops(levels, max_shops)

	var state := RunStateRef.new()
	state.seed = p_seed
	state.current_node_id = -1
	for level in levels:
		for node in level:
			state.nodes[node.id] = node
	return state


# Connect each node at level L to 1-2 nodes at level L+1, without crossings.
# Approach: nodes within a level are kept in a fixed order; an edge connects
# index i at level L to index j at level L+1 only if all chosen edges from
# the level form a non-crossing fan. We always include "nearest neighbor"
# edges so every node at L+1 has at least one parent and every node at L
# has at least one child.
static func _connect_levels(levels: Array, rng: RandomNumberGenerator) -> void:
	for li in range(levels.size() - 1):
		var top: Array = levels[li]
		var bot: Array = levels[li + 1]
		# Map each top index to a primary bottom index, monotonically increasing,
		# covering all bottom indices (so every bottom has a parent).
		var primary: Array[int] = []
		for ti in range(top.size()):
			var bi := int(round(float(ti) * float(bot.size() - 1) / max(1.0, float(top.size() - 1))))
			if bot.size() == 1:
				bi = 0
			primary.append(bi)
		# Ensure every bottom index has at least one primary parent.
		var covered := {}
		for bi in primary:
			covered[bi] = true
		for bi in range(bot.size()):
			if not covered.has(bi):
				# attach to nearest top index
				var best_ti := 0
				var best_dist := 1 << 30
				for ti in range(top.size()):
					var d := abs(primary[ti] - bi)
					if d < best_dist:
						best_dist = d
						best_ti = ti
				primary[best_ti] = bi
				covered[bi] = true
		# Now optionally add a second edge per top node (to bi-1 or bi+1) with
		# probability 0.5, only if it does not cross. "Does not cross" means:
		# for sorted top index i, its added edge endpoint must be >= primary[i-1]
		# and <= primary[i+1] (with virtual neighbours as their own primary).
		for ti in range(top.size()):
			var node: MapNode = top[ti]
			node.next_ids = [primary[ti]] as Array[int]
		for ti in range(top.size()):
			if rng.randf() < 0.5:
				var candidates: Array[int] = []
				var p := primary[ti]
				if p - 1 >= 0:
					candidates.append(p - 1)
				if p + 1 < bot.size():
					candidates.append(p + 1)
				# Filter by non-crossing constraint.
				var allowed: Array[int] = []
				for c in candidates:
					var ok := true
					if ti - 1 >= 0 and c < primary[ti - 1]:
						ok = false
					if ti + 1 < top.size() and c > primary[ti + 1]:
						ok = false
					if ok:
						allowed.append(c)
				if not allowed.is_empty():
					var pick: int = allowed[rng.randi_range(0, allowed.size() - 1)]
					var node: MapNode = top[ti]
					if not node.next_ids.has(pick):
						node.next_ids.append(pick)
		# Convert bottom indices stored in next_ids to actual node ids.
		for ti in range(top.size()):
			var node: MapNode = top[ti]
			var resolved: Array[int] = []
			for bi in node.next_ids:
				resolved.append((bot[int(bi)] as MapNode).id)
			resolved.sort()
			node.next_ids = resolved


# For every path from a level-1 node to the boss, no run of SHOP nodes
# longer than max_shops. We enforce by walking depth-by-depth: if a node's
# parents all have a chain of `max_shops` shops ending at them, this node
# must be COMBAT (or BOSS).
static func _enforce_max_consecutive_shops(levels: Array, max_shops: int) -> void:
	var streak := {}  # node_id -> int (longest run of SHOPs ending at this node)
	for li in range(levels.size()):
		var level: Array = levels[li]
		for node in level:
			var parent_max := 0
			if li == 0:
				parent_max = 0
			else:
				var prev: Array = levels[li - 1]
				# A node's "incoming" run is the max over parents whose next_ids contain it.
				var best := -1
				for p in prev:
					var p_node: MapNode = p
					for nid in p_node.next_ids:
						if int(nid) == node.id:
							var s := int(streak.get(p_node.id, 0))
							if s > best:
								best = s
							break
				if best < 0:
					best = 0  # unreached; should not happen if generator is sound
				parent_max = best
			if node.type == MapNode.NodeType.SHOP and parent_max >= max_shops:
				node.type = MapNode.NodeType.COMBAT
				streak[node.id] = 0
			elif node.type == MapNode.NodeType.SHOP:
				streak[node.id] = parent_max + 1
			else:
				streak[node.id] = 0
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `make test`
Expected: all `test_map_generator.gd` cases pass, including reachability and determinism.

- [ ] **Step 5: Commit**

```bash
git add scripts/map/map_generator.gd tests/unit/test_map_generator.gd
git commit -m "feat(map): implement MapGenerator with non-crossing edges and shop streak rule"
```

---

## Task 5: Add `max_consecutive_shops` test for the generator

**Files:**
- Modify: `tests/unit/test_map_generator.gd`

- [ ] **Step 1: Write the failing test**

Append to `tests/unit/test_map_generator.gd`:

```gdscript
func test_no_path_exceeds_max_consecutive_shops() -> void:
	var cfg := DataManager.get_map_config()
	cfg["max_consecutive_shops"] = 2
	cfg["shop_probability"] = 0.95  # force lots of shops
	var state = MapGenerator.generate(98765, cfg)
	# DFS all root-to-boss paths, assert no run > 2 shops.
	var roots: Array[int] = []
	for id_key in state.nodes.keys():
		var node: MapNode2 = state.nodes[id_key]
		if node.depth == 1:
			roots.append(node.id)
	for root in roots:
		_walk(state, root, 0, 2)


func _walk(state, node_id: int, current_run_count: int, limit: int) -> void:
	var n = state.nodes[node_id]
	var run_after := 0
	if n.type == MapNode2.NodeType.SHOP:
		run_after = current_run_count + 1
	else:
		run_after = 0
	assert_true(run_after <= limit, "shop streak %d exceeds %d at node %d" % [run_after, limit, node_id])
	for next_id in n.next_ids:
		_walk(state, int(next_id), run_after, limit)
```

- [ ] **Step 2: Run test to verify it passes**

Run: `make test`
Expected: pass. If it fails, the generator's streak enforcement has a bug — fix it before continuing.

- [ ] **Step 3: Commit**

```bash
git add tests/unit/test_map_generator.gd
git commit -m "test(map): assert no path exceeds max_consecutive_shops"
```

---

## Task 6: Add `Phase.MAP` and `current_run` / `last_run_result` fields to GameManager

**Files:**
- Modify: `scripts/autoload/game_manager.gd`
- Test: `tests/integration/test_game_manager.gd` (small additions)

- [ ] **Step 1: Write the failing test**

Open `tests/integration/test_game_manager.gd` and append:

```gdscript
func test_phase_map_exists() -> void:
	assert_true(GameManager.Phase.keys().has("MAP"))


func test_initial_run_state_is_null() -> void:
	GameManager.current_run = null
	GameManager.last_run_result = {}
	assert_null(GameManager.current_run)
	assert_eq(GameManager.last_run_result, {})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `make test`
Expected: failure — `Phase.MAP` does not exist or fields are missing.

- [ ] **Step 3: Modify `GameManager`**

Edit `scripts/autoload/game_manager.gd`.

Replace the `Phase` enum line:

```gdscript
enum Phase { MAIN_MENU, SHOP, DICE_SELECT, COMBAT, MAP }
```

Add new fields next to `var current_round: int = 1`:

```gdscript
var current_run: RunState = null
var last_run_result: Dictionary = {}
```

Add the `RunState` preload near the top of the file (after `extends Node`):

```gdscript
const RunState := preload("res://scripts/map/run_state.gd")
const MapGeneratorRef := preload("res://scripts/map/map_generator.gd")
const MapNodeRef := preload("res://scripts/map/map_node.gd")
```

In `_change_phase`, add the MAP arm to the existing match:

```gdscript
		Phase.MAP:
			get_tree().change_scene_to_file("res://scenes/map/map_screen.tscn")
```

(The scene file is created in Task 12; it's fine to add this match arm now since `_change_phase` is only invoked for MAP after Task 9.)

In `build_save_data`, ensure `current_run` and `last_run_result` are NOT included. (They aren't, by virtue of not being added — verify by reading the function.)

In `_apply_normalized_save_data`, after the existing assignments add an explicit clear:

```gdscript
	current_run = null
	last_run_result = {}
```

Also handle a `MAP` phase in a save (which we shouldn't write, but defensively). At the top of `build_save_data`, the existing block coerces COMBAT to SHOP when not in tutorial; extend it to also coerce MAP to SHOP:

```gdscript
	if (save_phase == Phase.COMBAT or save_phase == Phase.MAP) and not TutorialManager.is_active():
		save_phase = Phase.SHOP
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `make test`
Expected: pass.

- [ ] **Step 5: Commit**

```bash
git add scripts/autoload/game_manager.gd tests/integration/test_game_manager.gd
git commit -m "feat(map): add Phase.MAP, current_run, last_run_result on GameManager"
```

---

## Task 7: Initialize `current_run` in `start_game`; clear in `start_tutorial_replay` and `skip_active_tutorial`

**Files:**
- Modify: `scripts/autoload/game_manager.gd`
- Test: `tests/integration/test_game_manager.gd`

- [ ] **Step 1: Write the failing test**

Append to `tests/integration/test_game_manager.gd`:

```gdscript
func test_start_game_creates_run() -> void:
	GameManager.current_run = null
	GameManager.start_game(true)  # skip tutorial intro
	assert_not_null(GameManager.current_run)
	assert_eq(GameManager.current_run.current_node_id, -1)
	assert_true(GameManager.current_run.nodes.size() >= 2)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `make test`
Expected: failure — `current_run` is null after `start_game`.

- [ ] **Step 3: Modify `start_game`, `start_tutorial_replay`, `skip_active_tutorial`**

In `scripts/autoload/game_manager.gd`, modify `start_game`. Just before `_change_phase(Phase.SHOP)` (i.e., right after the existing reset/tutorial branching), add a call:

```gdscript
	current_run = MapGeneratorRef.generate(randi(), DataManager.get_map_config())
	last_run_result = {}
```

Place this at the start of `start_game` after `_reset_run_state()`:

```gdscript
func start_game(skip_tutorial_intro: bool = false) -> void:
	delete_save()
	_reset_run_state()
	current_run = MapGeneratorRef.generate(randi(), DataManager.get_map_config())
	last_run_result = {}
	if skip_tutorial_intro:
		# ... (rest unchanged)
```

In `start_tutorial_replay`, immediately after `_reset_run_state()`:

```gdscript
	current_run = null
	last_run_result = {}
```

In `skip_active_tutorial`, after `_reset_run_state()`:

```gdscript
	current_run = null
	last_run_result = {}
```

(Tutorial replay and skip flows are intentionally non-run; you exit them into the legacy single-round loop.)

- [ ] **Step 4: Run tests to verify they pass**

Run: `make test`
Expected: pass.

- [ ] **Step 5: Commit**

```bash
git add scripts/autoload/game_manager.gd tests/integration/test_game_manager.gd
git commit -m "feat(map): initialize current_run in start_game; clear in tutorial flows"
```

---

## Task 8: Split `advance_round` and add `complete_current_node`, `end_run`, `abandon_run`

**Files:**
- Modify: `scripts/autoload/game_manager.gd`
- Test: `tests/integration/test_game_manager.gd`

- [ ] **Step 1: Write the failing tests**

Append to `tests/integration/test_game_manager.gd`:

```gdscript
func test_advance_round_outside_run_goes_to_shop() -> void:
	GameManager.current_run = null
	GameManager.last_run_result = {}
	GameManager.current_round = 1
	GameManager.advance_round()
	assert_eq(GameManager.current_phase, GameManager.Phase.SHOP)
	assert_eq(GameManager.current_round, 2)


func test_complete_current_node_in_run_after_first_combat_goes_to_map() -> void:
	GameManager.start_game(true)
	# After start_game, current_node_id is -1 and phase is SHOP (not under tutorial).
	# Simulate the first combat ending in victory:
	GameManager.complete_current_node()
	assert_eq(GameManager.current_phase, GameManager.Phase.MAP)
	assert_eq(GameManager.current_round, 2)


func test_end_run_victory_returns_to_main_menu_with_result() -> void:
	GameManager.start_game(true)
	GameManager.end_run(true)
	assert_eq(GameManager.current_phase, GameManager.Phase.MAIN_MENU)
	assert_null(GameManager.current_run)
	assert_eq(bool(GameManager.last_run_result.get("victory", false)), true)


func test_abandon_run_clears_run_without_result() -> void:
	GameManager.start_game(true)
	GameManager.abandon_run()
	assert_null(GameManager.current_run)
	assert_eq(GameManager.last_run_result, {})
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `make test`
Expected: failures — methods do not exist or behavior is wrong.

- [ ] **Step 3: Refactor `advance_round` and add new methods**

Edit `scripts/autoload/game_manager.gd`. Replace `advance_round` with:

```gdscript
func _apply_round_advance() -> void:
	var reward := 10 + 5 * current_round
	coins += reward
	coins_changed.emit(coins)
	current_round += 1
	target_score = int(floor(BASE_TARGET * pow(1.5, current_round - 1)))
	selected_dice.clear()


func advance_round() -> void:
	# Legacy single-round flow: bump round and return to shop.
	_apply_round_advance()
	_change_phase(Phase.SHOP)
```

Add new methods at the end of the file:

```gdscript
func complete_current_node() -> void:
	# Called after a victorious COMBAT (CombatScreen end_combat dispatch) or
	# after a SHOP node Continue (Shop "Continue" button) while in a run.
	if current_run == null:
		push_warning("complete_current_node called outside of a run")
		return
	var node: MapNode = current_run.get_current_node()
	if node == null:
		# Onboarding: first combat after start_game (current_node_id == -1).
		_apply_round_advance()
		_change_phase(Phase.MAP)
		return
	match node.type:
		MapNodeRef.NodeType.COMBAT:
			_apply_round_advance()
			_change_phase(Phase.MAP)
		MapNodeRef.NodeType.SHOP:
			_change_phase(Phase.MAP)
		MapNodeRef.NodeType.BOSS:
			_apply_round_advance()
			end_run(true)


func enter_map_node(node_id: int) -> void:
	if current_run == null:
		push_warning("enter_map_node called outside of a run")
		return
	var available := current_run.available_node_ids()
	if not available.has(node_id):
		push_warning("enter_map_node ignored: node %d not in available %s" % [node_id, available])
		return
	current_run.current_node_id = node_id
	var node: MapNode = current_run.nodes[node_id]
	# Boss inherits a higher target via boss_blind_multiplier on top of current target.
	if node.type == MapNodeRef.NodeType.BOSS:
		var mult := float(DataManager.get_map_config().get("boss_blind_multiplier", 1.5))
		target_score = int(floor(float(target_score) * mult))
	match node.type:
		MapNodeRef.NodeType.COMBAT, MapNodeRef.NodeType.BOSS:
			_change_phase(Phase.COMBAT)
		MapNodeRef.NodeType.SHOP:
			_change_phase(Phase.SHOP)


func end_run(victory: bool) -> void:
	last_run_result = {
		"victory": victory,
		"round": current_round,
		"total_score": total_score,
		"coins": coins,
	}
	current_run = null
	_change_phase(Phase.MAIN_MENU)


func abandon_run() -> void:
	current_run = null
	last_run_result = {}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `make test`
Expected: pass.

- [ ] **Step 5: Commit**

```bash
git add scripts/autoload/game_manager.gd tests/integration/test_game_manager.gd
git commit -m "feat(map): add complete_current_node, enter_map_node, end_run, abandon_run"
```

---

## Task 9: Make `end_combat` route-aware (run-driven dispatch)

**Files:**
- Modify: `scripts/autoload/game_manager.gd`
- Test: `tests/integration/test_game_manager.gd`

- [ ] **Step 1: Write the failing tests**

Append to `tests/integration/test_game_manager.gd`:

```gdscript
func test_end_combat_in_run_victory_routes_through_complete_current_node() -> void:
	GameManager.start_game(true)
	# First combat in run — current_node_id == -1.
	GameManager.end_combat(GameManager.target_score, true)
	assert_eq(GameManager.current_phase, GameManager.Phase.MAP)


func test_end_combat_in_run_defeat_calls_end_run() -> void:
	GameManager.start_game(true)
	GameManager.end_combat(0, false)
	assert_eq(GameManager.current_phase, GameManager.Phase.MAIN_MENU)
	assert_null(GameManager.current_run)
	assert_eq(bool(GameManager.last_run_result.get("victory", false)), false)


func test_end_combat_outside_run_uses_legacy_advance_or_main_menu() -> void:
	GameManager.current_run = null
	GameManager.last_run_result = {}
	GameManager.current_round = 1
	GameManager.end_combat(GameManager.target_score, true)
	assert_eq(GameManager.current_phase, GameManager.Phase.SHOP)
	assert_eq(GameManager.current_round, 2)
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `make test`
Expected: failures — `end_combat` still uses the legacy path even in a run.

- [ ] **Step 3: Modify `end_combat`**

Replace `end_combat` in `scripts/autoload/game_manager.gd`:

```gdscript
func end_combat(final_score: int, target_beaten: bool) -> void:
	total_score = final_score
	score_changed.emit(total_score)
	PokiSDK.gameplay_stop()
	if current_run != null:
		if target_beaten:
			complete_current_node()
		else:
			end_run(false)
		return
	if target_beaten:
		advance_round()
	else:
		go_to_main_menu()
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `make test`
Expected: pass.

- [ ] **Step 5: Commit**

```bash
git add scripts/autoload/game_manager.gd tests/integration/test_game_manager.gd
git commit -m "feat(map): make end_combat run-aware"
```

---

## Task 10: Make Shop "Combat" button route-aware (Continue when in SHOP node)

**Files:**
- Modify: `scenes/shop/shop_screen.gd`
- Test: `tests/integration/test_run_flow.gd` (new)

- [ ] **Step 1: Identify the existing button**

Find the existing combat-button handler in `scenes/shop/shop_screen.gd`. It calls `GameManager.go_to_combat()`. We won't search-and-replace blindly — locate it first:

Run: `grep -n -E "go_to_combat|on_combat_button|_combat_btn" scenes/shop/shop_screen.gd`

You should see one or more sites. The key call is `GameManager.go_to_combat()` in the button's `pressed` handler.

- [ ] **Step 2: Write the integration test**

Create `tests/integration/test_run_flow.gd`:

```gdscript
extends GutTest

const ShopScreen := preload("res://scenes/shop/shop_screen.gd")


func _enter_shop_node() -> void:
	GameManager.start_game(true)
	# Simulate first combat victory to land on the map.
	GameManager.end_combat(GameManager.target_score, true)
	# Find a SHOP node we can enter.
	var shop_id := -1
	for id_key in GameManager.current_run.available_node_ids():
		var node = GameManager.current_run.nodes[id_key]
		if node.type == MapNode.NodeType.SHOP:
			shop_id = int(id_key)
			break
	if shop_id == -1:
		# Force a shop into the available frontier by patching; deterministic seed makes this rare.
		# Fallback: fabricate a shop node and link it.
		var shop_node := MapNode.new(9999, MapNode.NodeType.SHOP, 1, [] as Array[int])
		GameManager.current_run.nodes[9999] = shop_node
		shop_id = 9999
	GameManager.enter_map_node(shop_id)


func test_shop_continue_in_run_returns_to_map() -> void:
	_enter_shop_node()
	assert_eq(GameManager.current_phase, GameManager.Phase.SHOP)
	# Simulate "Continue" press by calling the public dispatcher used by the button.
	GameManager.shop_continue()
	assert_eq(GameManager.current_phase, GameManager.Phase.MAP)


func test_shop_continue_outside_run_goes_to_combat() -> void:
	GameManager.current_run = null
	GameManager.last_run_result = {}
	GameManager.shop_continue()
	assert_eq(GameManager.current_phase, GameManager.Phase.COMBAT)
```

- [ ] **Step 3: Run test to verify it fails**

Run: `make test`
Expected: failure — `shop_continue` does not exist on `GameManager`.

- [ ] **Step 4: Add the dispatcher on `GameManager`**

In `scripts/autoload/game_manager.gd`, add:

```gdscript
func shop_continue() -> void:
	# Single entry point used by the Shop "Combat" / "Continue" button.
	# - Outside a run: legacy → go to combat.
	# - In a run, current node is a SHOP: complete the node, return to map.
	# - In a run, no node entered yet (onboarding): go to combat.
	if current_run == null:
		_change_phase(Phase.COMBAT)
		return
	var node: MapNode = current_run.get_current_node()
	if node == null:
		_change_phase(Phase.COMBAT)
		return
	if node.type == MapNodeRef.NodeType.SHOP:
		complete_current_node()
		return
	# Defensive: should not be in Shop while current node is COMBAT/BOSS.
	push_warning("shop_continue called with unexpected node type")
	_change_phase(Phase.MAP)
```

- [ ] **Step 5: Wire the Shop button to the dispatcher and update its label**

Edit `scenes/shop/shop_screen.gd`. Replace the call site `GameManager.go_to_combat()` (in the button handler) with `GameManager.shop_continue()`.

Then update the button label to reflect run state. Find the place where the combat button is configured (search for the button text — likely "COMBAT" or "Combat"). Add or modify the text-update logic so that on `_ready` or on `phase_changed`:

```gdscript
func _update_combat_button_label() -> void:
	var in_run_shop := false
	if GameManager.current_run != null:
		var node: MapNode = GameManager.current_run.get_current_node()
		if node != null and node.type == MapNode.NodeType.SHOP:
			in_run_shop = true
	# Replace the actual node reference with the existing button variable in this file.
	if in_run_shop:
		_combat_btn.text = "CONTINUE"
	else:
		_combat_btn.text = "COMBAT"
```

Call `_update_combat_button_label()` at the end of `_ready()`. (If the existing file uses different button names, substitute the real node path; the principle is "set text based on run state".)

- [ ] **Step 6: Run tests to verify they pass**

Run: `make test`
Expected: pass.

- [ ] **Step 7: Commit**

```bash
git add scripts/autoload/game_manager.gd scenes/shop/shop_screen.gd tests/integration/test_run_flow.gd
git commit -m "feat(map): route Shop Continue through GameManager.shop_continue"
```

---

## Task 11: Create `MapNodeButton` scene + script

**Files:**
- Create: `scenes/map/map_node_button.tscn`
- Create: `scenes/map/map_node_button.gd`
- Test: smoke covered by `test_map_screen_smoke.gd` in Task 13

- [ ] **Step 1: Create the script**

Create `scenes/map/map_node_button.gd`:

```gdscript
extends Button
class_name MapNodeButton

signal node_clicked(node_id: int)

const MapNodeRef := preload("res://scripts/map/map_node.gd")

const COLOR_AVAILABLE := Color(1.0, 0.95, 0.6)
const COLOR_LOCKED := Color(0.5, 0.5, 0.5)
const COLOR_COMPLETED := Color(0.4, 0.8, 0.4)
const COLOR_BOSS := Color(0.9, 0.3, 0.3)

var node_id: int = -1
var node_type: int = MapNodeRef.NodeType.COMBAT
var state: String = "locked"  # one of: available, locked, completed


func configure(p_id: int, p_type: int, p_state: String) -> void:
	node_id = p_id
	node_type = p_type
	state = p_state
	_apply_visual()
	disabled = state != "available"


func _ready() -> void:
	pressed.connect(_on_pressed)
	custom_minimum_size = Vector2(56, 56)
	_apply_visual()


func _on_pressed() -> void:
	if state == "available":
		emit_signal("node_clicked", node_id)


func _apply_visual() -> void:
	var label := _icon_for_type(node_type)
	text = label
	var col := COLOR_LOCKED
	if state == "available":
		col = COLOR_BOSS if node_type == MapNodeRef.NodeType.BOSS else COLOR_AVAILABLE
	elif state == "completed":
		col = COLOR_COMPLETED
	add_theme_color_override("font_color", col)


func _icon_for_type(t: int) -> String:
	match t:
		MapNodeRef.NodeType.COMBAT:
			return "⚔"
		MapNodeRef.NodeType.SHOP:
			return "$"
		MapNodeRef.NodeType.BOSS:
			return "☠"
	return "?"
```

- [ ] **Step 2: Create the scene file**

Create `scenes/map/map_node_button.tscn` as a minimal Button scene with the script attached. Use the editor or hand-write the resource. Hand-written:

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scenes/map/map_node_button.gd" id="1"]

[node name="MapNodeButton" type="Button"]
custom_minimum_size = Vector2(56, 56)
text = "?"
script = ExtResource("1")
```

- [ ] **Step 3: Run static check**

Run: `make static-check`
Expected: pass — Godot import succeeds.

- [ ] **Step 4: Commit**

```bash
git add scenes/map/map_node_button.gd scenes/map/map_node_button.tscn
git commit -m "feat(map): add MapNodeButton scene and script"
```

---

## Task 12: Create `MapScreen` scene + script (rendering and click dispatch)

**Files:**
- Create: `scenes/map/map_screen.tscn`
- Create: `scenes/map/map_screen.gd`

- [ ] **Step 1: Create the script**

Create `scenes/map/map_screen.gd`:

```gdscript
extends Control

const MapNodeButtonScene := preload("res://scenes/map/map_node_button.tscn")
const MapNodeRef := preload("res://scripts/map/map_node.gd")

const LEVEL_SPACING := 120.0
const NODE_SPACING := 80.0
const EDGE_COLOR_DIM := Color(0.5, 0.5, 0.5, 0.6)
const EDGE_COLOR_AVAILABLE := Color(1.0, 0.95, 0.6, 0.95)

@onready var _coin_label: Label = %CoinLabel
@onready var _map_container: Control = %MapContainer

var _button_by_id: Dictionary = {}     # int -> MapNodeButton
var _position_by_id: Dictionary = {}   # int -> Vector2 (center of button)


func _ready() -> void:
	_coin_label.text = str(GameManager.coins)
	_render_map()
	_map_container.draw.connect(_draw_edges)


func _render_map() -> void:
	for c in _map_container.get_children():
		c.queue_free()
	_button_by_id.clear()
	_position_by_id.clear()

	var run := GameManager.current_run
	if run == null:
		return

	# Group nodes by depth.
	var levels: Dictionary = {}
	for id_key in run.nodes.keys():
		var node: MapNode = run.nodes[id_key]
		if not levels.has(node.depth):
			levels[node.depth] = []
		levels[node.depth].append(node)

	var depths := levels.keys()
	depths.sort()
	for d in depths:
		var level: Array = levels[d]
		# Sort within level by id for stable layout.
		level.sort_custom(func(a, b): return a.id < b.id)
		var count := level.size()
		for i in range(count):
			var node: MapNode = level[i]
			var x := float(d) * LEVEL_SPACING
			var y := (float(i) - (float(count) - 1.0) * 0.5) * NODE_SPACING
			var btn: MapNodeButton = MapNodeButtonScene.instantiate()
			_map_container.add_child(btn)
			btn.position = Vector2(x, y)
			btn.configure(node.id, node.type, _state_for(node, run))
			btn.node_clicked.connect(_on_node_clicked)
			_button_by_id[node.id] = btn
			_position_by_id[node.id] = btn.position + btn.custom_minimum_size * 0.5

	_map_container.queue_redraw()


func _state_for(node: MapNode, run) -> String:
	if node.id == run.current_node_id:
		return "completed"
	if run.available_node_ids().has(node.id):
		return "available"
	return "locked"


func _on_node_clicked(node_id: int) -> void:
	GameManager.enter_map_node(node_id)


func _draw_edges() -> void:
	var run := GameManager.current_run
	if run == null:
		return
	var available := run.available_node_ids()
	for id_key in run.nodes.keys():
		var node: MapNode = run.nodes[id_key]
		var from_pos: Vector2 = _position_by_id.get(node.id, Vector2.ZERO)
		for next_id in node.next_ids:
			var to_pos: Vector2 = _position_by_id.get(int(next_id), Vector2.ZERO)
			var col := EDGE_COLOR_DIM
			if node.id == run.current_node_id and available.has(int(next_id)):
				col = EDGE_COLOR_AVAILABLE
			elif run.current_node_id == -1 and node.depth == 1 and available.has(node.id):
				col = EDGE_COLOR_AVAILABLE
			_map_container.draw_line(from_pos, to_pos, col, 2.0)
```

- [ ] **Step 2: Create the scene file**

Create `scenes/map/map_screen.tscn` (hand-written; the actual layout can be tuned later):

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scenes/map/map_screen.gd" id="1"]

[node name="MapScreen" type="Control"]
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1")

[node name="Background" type="ColorRect" parent="."]
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0.08, 0.08, 0.12, 1.0)

[node name="Margin" type="MarginContainer" parent="."]
anchor_right = 1.0
anchor_bottom = 1.0
theme_override_constants/margin_left = 24
theme_override_constants/margin_top = 24
theme_override_constants/margin_right = 24
theme_override_constants/margin_bottom = 24

[node name="VBox" type="VBoxContainer" parent="Margin"]

[node name="TopBar" type="HBoxContainer" parent="Margin/VBox"]

[node name="Title" type="Label" parent="Margin/VBox/TopBar"]
text = "MAP"
size_flags_horizontal = 3

[node name="CoinLabel" type="Label" parent="Margin/VBox/TopBar"]
unique_name_in_owner = true
text = "0"

[node name="MapContainer" type="Control" parent="Margin/VBox"]
unique_name_in_owner = true
custom_minimum_size = Vector2(900, 540)
size_flags_vertical = 3
```

- [ ] **Step 3: Run static check**

Run: `make static-check`
Expected: pass.

- [ ] **Step 4: Commit**

```bash
git add scenes/map/map_screen.tscn scenes/map/map_screen.gd
git commit -m "feat(map): add MapScreen scene with node rendering and edge drawing"
```

---

## Task 13: MapScreen smoke test

**Files:**
- Create: `tests/smoke/test_map_screen_smoke.gd`

- [ ] **Step 1: Write the test**

Create `tests/smoke/test_map_screen_smoke.gd`:

```gdscript
extends GutTest

const MapScreenScene := preload("res://scenes/map/map_screen.tscn")
const MapNode := preload("res://scripts/map/map_node.gd")
const RunState := preload("res://scripts/map/run_state.gd")


func before_each() -> void:
	# Build a tiny run: one combat node, one boss.
	var run := RunState.new()
	var n1 := MapNode.new(1, MapNode.NodeType.COMBAT, 1, [2] as Array[int])
	var n2 := MapNode.new(2, MapNode.NodeType.BOSS, 2, [] as Array[int])
	run.nodes = {1: n1, 2: n2}
	run.current_node_id = -1
	run.seed = 1
	GameManager.current_run = run


func after_each() -> void:
	GameManager.current_run = null


func test_map_screen_instantiates() -> void:
	var screen = MapScreenScene.instantiate()
	add_child_autofree(screen)
	await get_tree().process_frame
	assert_not_null(screen)
```

- [ ] **Step 2: Run test to verify it passes**

Run: `make test`
Expected: pass.

- [ ] **Step 3: Commit**

```bash
git add tests/smoke/test_map_screen_smoke.gd
git commit -m "test(map): add MapScreen smoke test"
```

---

## Task 14: Show ResultsOverlay on MainMenu when `last_run_result` is set

**Files:**
- Modify: `scenes/main_menu/main_menu.gd`
- Test: cannot easily integration-test the overlay UI; rely on visual check + GameManager-side test

- [ ] **Step 1: Add the overlay builder and `_show_result_overlay`**

Edit `scenes/main_menu/main_menu.gd`. Append to `_ready()` (after the existing initialization lines, ideally just before the existing settings overlay build):

```gdscript
	if not GameManager.last_run_result.is_empty():
		_show_result_overlay()
```

Add the new method:

```gdscript
func _show_result_overlay() -> void:
	var data := GameManager.last_run_result.duplicate()
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var panel := _make_panel(DARK, GOLD, Vector2(420, 0), 32)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	var title := _make_pixel_label("VICTORY" if bool(data.get("victory", false)) else "DEFEATED", 24, GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var stats := _make_pixel_label(
		"Round: %d\nScore: %d\nCoins: %d" % [int(data.get("round", 0)), int(data.get("total_score", 0)), int(data.get("coins", 0))],
		14,
		Color.WHITE,
	)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stats)

	var btn := _make_colored_button("CONTINUE", Vector2(180, 48), GREEN, GREEN.lightened(0.15), 14)
	btn.pressed.connect(func():
		GameManager.last_run_result = {}
		overlay.queue_free()
	)
	var btn_center := CenterContainer.new()
	vbox.add_child(btn_center)
	btn_center.add_child(btn)
```

(If `_make_panel`, `_make_pixel_label`, `_make_colored_button` aren't already in `main_menu.gd`, they exist in `pixel_bg.gd` which it extends — verify by grepping.)

- [ ] **Step 2: Run static check**

Run: `make static-check`
Expected: pass.

- [ ] **Step 3: Commit**

```bash
git add scenes/main_menu/main_menu.gd
git commit -m "feat(map): show run results overlay on MainMenu after end_run"
```

---

## Task 15: Wire CombatScreen "back to menu" pause action to `abandon_run`

**Files:**
- Modify: `scenes/combat/combat_screen.gd`
- Test: `tests/integration/test_run_flow.gd`

- [ ] **Step 1: Identify the menu return site**

Run: `grep -n -E "go_to_main_menu|MenuButton|pause_overlay" scenes/combat/combat_screen.gd`

You'll find one or more sites that take the player from Combat back to the main menu (typically through a pause overlay's "QUIT TO MENU" button). The current call is `GameManager.go_to_main_menu()`.

- [ ] **Step 2: Write the failing test**

Append to `tests/integration/test_run_flow.gd`:

```gdscript
func test_abandon_in_combat_does_not_set_last_run_result() -> void:
	GameManager.start_game(true)
	GameManager.abandon_run()
	GameManager.go_to_main_menu()
	assert_null(GameManager.current_run)
	assert_eq(GameManager.last_run_result, {})
```

- [ ] **Step 3: Run test to verify it passes**

Run: `make test`
Expected: pass already (test only exercises GameManager methods we already wrote).

- [ ] **Step 4: Modify the pause/quit-to-menu handler**

In `scenes/combat/combat_screen.gd`, locate the handler that calls `GameManager.go_to_main_menu()` from a pause/quit button. Replace it with:

```gdscript
	if GameManager.current_run != null:
		GameManager.abandon_run()
	GameManager.go_to_main_menu()
```

Apply the same change in `scenes/shop/shop_screen.gd` if it has a similar quit-to-menu path. (Run `grep -n go_to_main_menu scenes/shop/shop_screen.gd`; if present, wrap the call.)

- [ ] **Step 5: Run tests and static check**

Run: `make test && make static-check`
Expected: pass.

- [ ] **Step 6: Commit**

```bash
git add scenes/combat/combat_screen.gd scenes/shop/shop_screen.gd tests/integration/test_run_flow.gd
git commit -m "feat(map): abandon run when player returns to main menu mid-run"
```

---

## Task 16: Boss multiplier integration test

**Files:**
- Modify: `tests/integration/test_run_flow.gd`

- [ ] **Step 1: Write the test**

Append to `tests/integration/test_run_flow.gd`:

```gdscript
func test_entering_boss_multiplies_target_score() -> void:
	GameManager.start_game(true)
	# Force a deterministic boss-only run for the test.
	var boss := MapNode.new(1, MapNode.NodeType.BOSS, 1, [] as Array[int])
	GameManager.current_run.nodes = {1: boss}
	GameManager.current_run.current_node_id = -1
	var pre_target := GameManager.target_score
	var mult := float(DataManager.get_map_config().get("boss_blind_multiplier", 1.5))
	GameManager.enter_map_node(1)
	assert_eq(GameManager.current_phase, GameManager.Phase.COMBAT)
	assert_eq(GameManager.target_score, int(floor(float(pre_target) * mult)))
```

- [ ] **Step 2: Run test to verify it passes**

Run: `make test`
Expected: pass.

- [ ] **Step 3: Commit**

```bash
git add tests/integration/test_run_flow.gd
git commit -m "test(map): assert boss node applies blind multiplier"
```

---

## Task 17: Save/load — verify run is not persisted

**Files:**
- Modify: `tests/integration/test_game_manager.gd`

- [ ] **Step 1: Write the test**

Append to `tests/integration/test_game_manager.gd`:

```gdscript
func test_save_does_not_serialize_run() -> void:
	GameManager.start_game(true)
	var data := GameManager.build_save_data()
	assert_false(data.has("current_run"))
	assert_false(data.has("last_run_result"))


func test_loading_save_clears_run_state() -> void:
	GameManager.start_game(true)
	var data := GameManager.build_save_data()
	GameManager.last_run_result = {"victory": true}
	GameManager.apply_save_data(data)
	assert_null(GameManager.current_run)
	assert_eq(GameManager.last_run_result, {})
```

- [ ] **Step 2: Run test to verify it passes**

Run: `make test`
Expected: pass — `build_save_data` was never modified to include the new fields, and Task 6 already added the explicit clear in `_apply_normalized_save_data`.

- [ ] **Step 3: Commit**

```bash
git add tests/integration/test_game_manager.gd
git commit -m "test(map): verify run state is not persisted in save"
```

---

## Task 18: Final validation

**Files:** none (verification only)

- [ ] **Step 1: Run the full validation loop**

Run: `make validate`
Expected: pass — tests, lint, format-check, typecheck, security all green.

- [ ] **Step 2: Manual smoke (editor)**

Open the project in Godot 4.6 and play it. Verify:

1. New Game from MainMenu → Shop appears (button says "COMBAT").
2. Press Combat → fight a round; on victory you arrive at the Map screen.
3. Map shows ~6 columns of nodes; only level-1 nodes are clickable.
4. Click an available Combat node → Combat screen with a higher target than before; win → back to Map.
5. Click an available Shop node → Shop appears, button now says "CONTINUE"; press → back to Map.
6. Reach the boss, win → MainMenu shows VICTORY overlay with stats.
7. Start another run, lose a combat → MainMenu shows DEFEATED overlay.
8. Start a run, hit the pause/quit-to-menu button mid-combat → MainMenu, no overlay.

If any step fails, fix and re-run `make validate` before committing.

- [ ] **Step 3: Commit any fixes**

If you made code changes during manual smoke, commit them per the existing pattern.

---

## Self-Review Notes

- **Spec coverage:** All sections of the design spec (architecture, run flow, generation, blinds, UI, tests, edge cases) are mapped to tasks. The addendum's reconciliation points (`current_round` reuse, `_apply_round_advance` split, no save persistence, abandon vs end_run) are covered in Tasks 6–9, 15, 17.
- **Placeholders:** No TBDs. Every step has either runnable code or an exact command.
- **Type consistency:** `MapNode.NodeType.{COMBAT, SHOP, BOSS}` is used consistently. `RunState.available_node_ids() -> Array[int]` matches all callers. `complete_current_node`, `enter_map_node`, `end_run`, `abandon_run`, `shop_continue` all defined in Task 8/10 and used identically afterward.
- **Risk note:** Task 10 step 1 grep is the only "discover then patch" step. If the Shop combat-button handler is more entangled than expected (e.g. multiple buttons share logic), you may need a small adapter — keep the call replacement minimal: `GameManager.go_to_combat()` → `GameManager.shop_continue()` and a label refresh on `phase_changed`.
