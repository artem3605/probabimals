# Map Screen — Roguelike Run Structure

**Date:** 2026-05-03
**Status:** Design approved, ready for planning

## Summary

Add a 4th top-level screen — **Map** — that turns the existing FleaMarket and Combat screens into nodes of a single run. The player's first round stays unchanged (FleaMarket → Combat) for onboarding, then a branching map opens. The player picks a path through ~5–7 nodes (Combat or Shop), ending in a Boss Combat. Victory or defeat returns to MainMenu via a results overlay.

This is the smallest slice that delivers a roguelike meta-loop: route choice, escalating risk, and a defined run boundary.

## Goals

- Introduce route-choice gameplay on top of the existing FleaMarket/Combat loop.
- Reuse existing screens as node types — no new combat or shop logic.
- Define a clean run lifecycle: `start_run → nodes → end_run`, with results visible to the player.
- Stay scoped to one well-bounded slice; leave richer roguelike features for later iterations.

## Non-Goals (Future Work)

- Additional node types: Elite, Event, Treasure, Mystery (`?`).
- Per-node reward picks (STS-style "choose 1 of 3").
- Pre-shown blind values per node (route planning by exact difficulty).
- Save/load of an in-progress run.
- Multi-chapter runs (one map = one run).
- Animations of player movement between nodes.
- Run statistics / persistent meta-progression.
- Visual themes per chapter.

---

## Architecture (Approach A)

`GameManager` gains a new phase and owns the active run. The map screen and run state are pure additions; FleaMarket and Combat screens are minimally adapted to ask `GameManager` what to do on exit instead of hardcoding their next phase.

### New Files

```
scenes/map/
  map_screen.tscn          # map screen root
  map_screen.gd            # renders nodes/edges, forwards clicks to GameManager
  map_node_button.tscn     # single node button (Combat / Shop / Boss)
  map_node_button.gd

scripts/map/
  run_state.gd             # RefCounted: nodes, current node, combats_completed, seed
  map_generator.gd         # RefCounted: generate(seed) -> RunState
  map_node.gd              # RefCounted: id, type, depth, next_ids
```

### Modified Files

- `scripts/autoload/game_manager.gd`
  - Add `Phase.MAP`.
  - Add `current_run: RunState` and `last_run_result: Dictionary` (or null).
  - Add methods: `start_run()`, `complete_onboarding_shop()`, `enter_map_node(node_id: int)`, `complete_current_node()`, `end_run(victory: bool)`.
- `scenes/main_menu/main_menu.gd`
  - On `_ready`, if `GameManager.last_run_result != null`, show ResultsOverlay.
  - Start button calls `GameManager.start_run()` instead of going straight to FleaMarket.
- `scenes/flea_market/flea_market_screen.gd`
  - Continue/Combat button branches:
    - If `current_run.current_node_id == -1` (onboarding shop): call `complete_onboarding_shop()`.
    - Else (shop node on map): call `complete_current_node()`.
  - Button label switches between "Combat" (onboarding) and "Continue" (map shop node).
- `scenes/combat/combat_screen.gd`
  - On victory: `GameManager.complete_current_node()`.
  - On defeat: `GameManager.end_run(false)`.
- `resources/data/map_config.json` (new data file)
  - Map shape parameters and boss multiplier.

### Module Boundaries

- `RunState` — pure data container. No logic beyond derived getters (e.g. `available_node_ids()`).
- `MapGenerator` — pure function: `generate(seed: int, config: Dictionary) -> RunState`. No global state, no autoloads.
- `MapNode` — pure data: `id`, `type` (enum: COMBAT, SHOP, BOSS), `depth`, `next_ids: Array[int]`.
- `MapScreen` — UI only. Reads `GameManager.current_run`, renders, emits clicks back to `GameManager`. No run logic.
- `GameManager` — orchestrator. Owns `current_run`, performs phase transitions.

---

## Run Flow

```
MainMenu
  └─ [Start] → start_run()
              → Phase.FLEA_MARKET (onboarding shop, current_node_id = -1)

FleaMarket (onboarding)
  └─ [Combat] → complete_onboarding_shop()
              → Phase.COMBAT (combats_completed = 0)

Combat (onboarding)
  └─ victory → complete_current_node()
              → Phase.MAP (combats_completed = 1)
  └─ defeat  → end_run(false) → ResultsOverlay → MainMenu

Map
  └─ click available node → enter_map_node(id)
       ├─ COMBAT / BOSS → Phase.COMBAT
       └─ SHOP          → Phase.FLEA_MARKET

Combat (map node)
  └─ victory:
      ├─ if BOSS → end_run(true) → ResultsOverlay → MainMenu
      └─ else    → Phase.MAP (combats_completed += 1)
  └─ defeat → end_run(false) → ResultsOverlay → MainMenu

FleaMarket (map node)
  └─ [Continue] → complete_current_node() → Phase.MAP
```

### `GameManager` Method Contracts

```gdscript
func start_run() -> void:
    # Called from MainMenu Start button.
    # Generates a new run, resets coins/dice_bag, enters Phase.FLEA_MARKET.
    current_run = MapGenerator.generate(randi(), DataManager.get_map_config())
    coins = STARTING_COINS
    dice_bag = DiceBag.new()
    last_run_result = null
    _set_phase(Phase.FLEA_MARKET)

func complete_onboarding_shop() -> void:
    # Called from FleaMarket when current_node_id == -1.
    # Transitions to onboarding combat (no node tracking yet).
    _set_phase(Phase.COMBAT)

func enter_map_node(node_id: int) -> void:
    # Called from MapScreen on click.
    # Validates node_id is in current_run.available_node_ids(); warns and returns if not.
    # Sets current_node_id, transitions to COMBAT or FLEA_MARKET by node type.

func complete_current_node() -> void:
    # Called from CombatScreen on victory or FleaMarket on Continue (map shop node).
    # If current node is COMBAT: combats_completed += 1, transition to MAP.
    # If current node is BOSS: combats_completed += 1, end_run(true).
    # If current node is SHOP: transition to MAP.
    # If current_node_id == -1 (onboarding combat completion): combats_completed = 1, transition to MAP.

func end_run(victory: bool) -> void:
    # Stores last_run_result, clears current_run, returns to MainMenu.
    last_run_result = {
        "victory": victory,
        "combats": current_run.combats_completed,
        "total_score": total_score,
        "coins": coins,
    }
    current_run = null
    _set_phase(Phase.MAIN_MENU)
```

---

## Map Structure & Generation

### Config (`resources/data/map_config.json`)

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

Validation at load time (`DataManager`): `depth >= 2`, all probabilities in `[0, 1]`, `min <= max` for node counts. On invalid values: `push_error`, fall back to defaults.

### Algorithm

`MapGenerator.generate(seed: int, config: Dictionary) -> RunState`:

1. Seed an RNG with `seed`.
2. Create level 0 (virtual start; no node, just an anchor for `current_node_id == -1`).
3. For each level `L` from 1 to `depth - 1`:
   - Pick node count uniformly in `[min_nodes_per_level, max_nodes_per_level]`.
   - For each node, assign type: SHOP with `shop_probability`, else COMBAT.
4. Create level `depth` with exactly one BOSS node.
5. Connect edges:
   - Each node at level `L` connects to 1–2 nodes at level `L+1`.
   - Connections are chosen so edges, when nodes are laid out vertically by index, do not cross.
   - Every node at levels `1..depth-1` must have at least one outgoing edge.
   - Every node at levels `1..depth` must have at least one incoming edge (i.e. reachable from start).
6. Post-process `max_consecutive_shops`: enumerate paths from any level-1 node to the boss (DFS); if any path has more than `max_consecutive_shops` SHOP nodes in a row, flip excess SHOPs to COMBAT.

### `RunState`

```
nodes: Dictionary[int, MapNode]   # node_id -> MapNode
current_node_id: int              # -1 initially (before any node entered)
combats_completed: int            # increments after COMBAT and BOSS nodes (and after onboarding combat)
seed: int                         # for reproducibility / debugging
```

Derived getters:
- `available_node_ids() -> Array[int]`:
  - If `current_node_id == -1`: return all level-1 node ids.
  - Else: return `nodes[current_node_id].next_ids`.

### `MapNode`

```
id: int
type: NodeType   # enum { COMBAT, SHOP, BOSS }
depth: int
next_ids: Array[int]
```

### Node Reachability

After generation, every node at levels `1..depth` must be reachable from a level-1 node, and every node at levels `1..depth-1` must reach the boss. The generator must guarantee this; tests assert it.

---

## Blinds

The existing combat blind formula is a function of "round number". This design replaces "round number" with `current_run.combats_completed`:

```gdscript
var combats_done := 0
if GameManager.current_run != null:
    combats_done = GameManager.current_run.combats_completed
target_score = base_blind * blind_growth_curve(combats_done)
```

For the BOSS node, multiply the result by `boss_blind_multiplier` from `map_config.json`.

The existing growth curve (whatever is in current Combat code) is preserved; only the input source changes. Pre-existing tests for the growth curve continue to pass.

---

## UI

### `MapScreen` Layout

```
Control root → Background → MarginContainer → VBoxContainer:
  ├─ TopBar: MenuButton, "MAP" title, CoinLabel
  ├─ MapContainer (Control with custom _draw for edges)
  │    └─ MapNodeButton instances, positioned by:
  │         x = depth * level_spacing_px
  │         y = (index_in_level - level_size / 2.0) * node_spacing_px
  └─ BottomBar: "Combats completed: X / total" subtitle
```

`MapContainer._draw()` iterates all nodes, draws a line from each to its `next_ids`. Edge color:
- Bright (highlighted) for edges leaving `current_node_id` (or all level-1 incoming edges if `current_node_id == -1`).
- Dimmed gray for all other edges.

### `MapNodeButton`

- Icon by type:
  - COMBAT: sword (placeholder)
  - SHOP: coin (placeholder)
  - BOSS: skull (placeholder)
- States:
  - `available`: full color, clickable.
  - `locked`: grayed out, not clickable.
  - `completed`: dimmed with checkmark.
- Click on `available` → emits `node_clicked(id)` → `MapScreen` calls `GameManager.enter_map_node(id)`.

### Results Overlay

After `end_run()`, MainMenu's `_ready()` checks `GameManager.last_run_result`. If non-null, shows an overlay:

```
┌─────────────────────────────┐
│   VICTORY  /  DEFEATED      │
│                             │
│   Combats won: X            │
│   Total score: Y            │
│   Coins remaining: Z        │
│                             │
│         [Continue]          │
└─────────────────────────────┘
```

`[Continue]` clears `last_run_result` and dismisses the overlay. Player can then press `[Start]` for a new run.

---

## Testing

### Unit Tests (`tests/unit/`)

- `test_map_generator.gd`:
  - Map has `depth + 1` levels (level 0 is the virtual start).
  - Level `depth` has exactly one node, type BOSS.
  - All nodes at levels `1..depth-1` are COMBAT or SHOP.
  - Every non-boss node has at least one outgoing edge.
  - Every node at levels `1..depth` is reachable from a level-1 node (BFS check).
  - Same seed → identical map (determinism).
  - On every path from a level-1 node to the boss, no run of SHOP nodes exceeds `max_consecutive_shops`.

- `test_run_state.gd`:
  - `current_node_id == -1` initially; `available_node_ids()` returns all level-1 nodes.
  - After setting `current_node_id` to a non-leaf node, `available_node_ids()` equals that node's `next_ids`.

### Integration Tests (`tests/integration/`)

- `test_run_flow.gd`:
  - `start_run()` → phase FLEA_MARKET, `current_run != null`, `combats_completed == 0`, `current_node_id == -1`.
  - `complete_onboarding_shop()` → phase COMBAT.
  - Simulate combat victory via `complete_current_node()` while `current_node_id == -1` → phase MAP, `combats_completed == 1`.
  - `enter_map_node(valid_id)` → correct phase by node type; `current_node_id` updated.
  - `enter_map_node(invalid_id)` → no phase change, warning emitted.
  - Victory on BOSS node via `complete_current_node()` → `end_run(true)`, `last_run_result.victory == true`, `current_run == null`, phase MAIN_MENU.
  - Defeat mid-map via `end_run(false)` → `last_run_result.victory == false`, `current_run == null`, phase MAIN_MENU.

### Smoke Tests (`tests/smoke/`)

- `test_map_screen_smoke.gd`: instantiate `MapScreen` with a fixture `RunState` (1 level + boss, ~3 nodes total) and assert it loads without errors.

### Validation Pipeline

`make test` picks up new tests automatically (GUT scans `tests/`). No Makefile changes required. `make static-check`, `make lint`, `make format-check` apply to new files unchanged.

---

## Error Handling & Edge Cases

- **Click on locked node:** `GameManager.enter_map_node()` validates `node_id ∈ current_run.available_node_ids()`. On mismatch: `push_warning`, return without changing state. UI also marks locked nodes non-clickable as a first-line defense.
- **`current_run == null` in `complete_current_node()`:** Possible only via misuse (e.g. test scene). `push_warning`, early return.
- **Invalid `map_config.json`:** Validate at load; on failure `push_error` and use defaults.
- **Game closed mid-run:** Run is lost. Save/load is explicit future work.
- **Generator fails reachability post-condition:** assert in debug builds; in release, regenerate with a different seed (bounded to e.g. 5 retries) before raising an error.

---

## Open Questions (None Blocking)

- Exact placeholder art for node icons — can use Godot built-in icons or simple ColorRects until art is ready.
- Edge rendering style (straight line vs. bezier) — pick whichever looks acceptable; not load-bearing.

---

## Future Work (Recap)

- Pre-shown per-node blinds (route planning).
- Elite / Event / Treasure / Mystery node types.
- STS-style post-combat reward picks.
- Run save/load.
- Multi-chapter (multiple maps per run, escalating between them).
- Movement animations and richer map visuals.
- Run statistics and meta-progression.
