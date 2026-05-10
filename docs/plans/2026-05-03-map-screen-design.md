# Map Screen — Roguelike Run Structure

**Date:** 2026-05-03
**Status:** Design approved, ready for planning

## Summary

Add a 4th top-level screen — **Map** — that turns the existing Shop and Combat screens into nodes of a single run. The player's first round stays unchanged (Shop → Combat) for onboarding, then a branching map opens. The player picks a path through ~5–7 nodes (Combat or Shop), ending in a Boss Combat. Victory or defeat returns to MainMenu via a results overlay.

This is the smallest slice that delivers a roguelike meta-loop: route choice, escalating risk, and a defined run boundary.

## Goals

- Introduce route-choice gameplay on top of the existing Shop/Combat loop.
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

`GameManager` gains a new phase and owns the active run. The map screen and run state are pure additions; Shop and Combat screens are minimally adapted to ask `GameManager` what to do on exit instead of hardcoding their next phase.

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
  - Start button calls `GameManager.start_run()` instead of going straight to Shop.
- `scenes/shop/shop_screen.gd`
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
              → Phase.SHOP (onboarding shop, current_node_id = -1)

Shop (onboarding)
  └─ [Combat] → complete_onboarding_shop()
              → Phase.COMBAT (combats_completed = 0)

Combat (onboarding)
  └─ victory → complete_current_node()
              → Phase.MAP (combats_completed = 1)
  └─ defeat  → end_run(false) → ResultsOverlay → MainMenu

Map
  └─ click available node → enter_map_node(id)
       ├─ COMBAT / BOSS → Phase.COMBAT
       └─ SHOP          → Phase.SHOP

Combat (map node)
  └─ victory:
      ├─ if BOSS → end_run(true) → ResultsOverlay → MainMenu
      └─ else    → Phase.MAP (combats_completed += 1)
  └─ defeat → end_run(false) → ResultsOverlay → MainMenu

Shop (map node)
  └─ [Continue] → complete_current_node() → Phase.MAP
```

### `GameManager` Method Contracts

```gdscript
func start_run() -> void:
    # Called from MainMenu Start button.
    # Generates a new run, resets coins/dice_bag, enters Phase.SHOP.
    current_run = MapGenerator.generate(randi(), DataManager.get_map_config())
    coins = STARTING_COINS
    dice_bag = DiceBag.new()
    last_run_result = null
    _set_phase(Phase.SHOP)

func complete_onboarding_shop() -> void:
    # Called from Shop when current_node_id == -1.
    # Transitions to onboarding combat (no node tracking yet).
    _set_phase(Phase.COMBAT)

func enter_map_node(node_id: int) -> void:
    # Called from MapScreen on click.
    # Validates node_id is in current_run.available_node_ids(); warns and returns if not.
    # Sets current_node_id, transitions to COMBAT or SHOP by node type.

func complete_current_node() -> void:
    # Called from CombatScreen on victory or Shop on Continue (map shop node).
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
  - `start_run()` → phase SHOP, `current_run != null`, `combats_completed == 0`, `current_node_id == -1`.
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

---

## Addendum (2026-05-03): Reconciliation With Existing Codebase

After reviewing the actual `scripts/autoload/game_manager.gd`, the design is reconciled with existing code as follows. The high-level architecture (Approach A: new `Phase.MAP`, `current_run` field, map screen + generator + state) is unchanged. The differences below take precedence over the original sections where they overlap.

### Reuse `current_round` as the Progression Counter

The original design proposed a new `combats_completed` field. This is replaced by reusing the existing `GameManager.current_round`. Rationale: `current_round` is already initialized in `_reset_run_state`, advanced by `advance_round()` (which also grants the coin reward and recomputes `target_score`), and serialized in save/load. Introducing a parallel counter would duplicate state and create two sources of truth for blind difficulty.

Concretely:

- `RunState` does **not** carry a combats counter. Progression is read from `GameManager.current_round`.
- After a victorious COMBAT or BOSS map node, `complete_current_node()` calls the existing `advance_round()` logic for reward + `target_score` bump. The transition target (Map vs. Shop vs. end_run) is decided by `complete_current_node()`, not by `advance_round()` itself — see "Splitting `advance_round`" below.
- Boss blind multiplier is applied on top of `target_score` only when entering the BOSS node, by `enter_map_node()`.

### Splitting `advance_round`

Current `advance_round()` does two things: (a) grant reward and bump `target_score`, (b) transition to `Phase.SHOP`. For a run, the destination phase depends on context (next map node, end of run, or — outside any run — keep legacy behavior). The fix:

- Extract the reward + target bump into a private helper, e.g. `_apply_round_advance()`.
- `advance_round()` keeps its current public signature and behavior for non-run callers (legacy single-round flow / loaded saves with no run): calls `_apply_round_advance()` then `_change_phase(Phase.SHOP)`.
- `complete_current_node()` (new) calls `_apply_round_advance()` directly, then decides next phase from run state.

### Onboarding = Existing First Combat

The original spec described an "onboarding shop / onboarding combat" with `current_node_id == -1`. In the actual codebase this is exactly the existing first round (`MainMenu → Shop → Combat`), optionally preceded by the tutorial intro combat. No new "onboarding" methods are introduced. Instead:

- `start_game()` (existing) is the entry point; it now also creates `current_run = MapGenerator.generate(...)` so a run is active from the start. The generated map is not visible until the first real combat completes.
- The first Shop → Combat cycle stays as it is. `CombatScreen` on victory calls `complete_current_node()`. Because `current_run.current_node_id == -1`, that call routes to `Phase.MAP` (instead of the legacy Shop loop).
- The earlier `complete_onboarding_shop()` method is **not** added — the existing Shop "Combat" button keeps calling `go_to_combat()` for the first cycle.

### Save / Load: Run Is Not Persisted

The map and run state are explicitly excluded from save/load.

- `build_save_data` / `apply_save_data` are **not** changed to include `current_run`, `last_run_result`, or any map data.
- On load, `current_run` is `null` and `last_run_result` is `null`. The game resumes in the legacy single-round flow at the saved phase (typically `SHOP`).
- This preserves backwards compatibility with v2 saves and matches the "run save/load is future work" non-goal.
- Closing the game mid-run loses the run. This is acceptable for the first iteration.

### Abandoning a Run

If the player returns to the main menu mid-run via an explicit "back to menu" / pause-quit action (not a combat defeat), this is an **abandon**, not a defeat:

- `current_run` is set to `null`.
- `last_run_result` is **not** populated.
- `ResultsOverlay` does **not** show on the next MainMenu visit.

`ResultsOverlay` only appears after `end_run(victory: bool)` is called from a real combat outcome (boss victory or mid-run defeat).

### `last_run_result` Is In-Memory Only

`last_run_result` is a transient field. It is not serialized into the save file. If the player quits the game after seeing the results overlay but before pressing Continue, the overlay does not reappear on next launch.

### Updated Method List on `GameManager`

The final method additions on `GameManager` for this slice are:

- `enter_map_node(node_id: int) -> void`
- `complete_current_node() -> void`
- `end_run(victory: bool) -> void`
- `abandon_run() -> void` (new — called from "back to menu" affordances when in a run)
- `_apply_round_advance() -> void` (private helper extracted from `advance_round`)

`start_game()` is modified (not replaced) to initialize `current_run`. `advance_round()` is refactored to call `_apply_round_advance()` then transition to `SHOP`, preserving its public behavior for non-run callers.
