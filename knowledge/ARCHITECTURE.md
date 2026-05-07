# Architecture

Probabimals is a Godot 4.6 GDScript dice strategy game. Runtime state is routed through autoload managers, player-facing surfaces are Godot scenes, and gameplay tuning is kept in JSON data under `resources/data/`.

## Runtime Flow

The normal run flow is:

`MainMenu -> Map -> DiceSelect -> Combat -> Map`

Map nodes decide which preparation surface comes next:

- **Combat/Boss nodes** route to `DiceSelect`, then `Combat`.
- **Shop nodes** route to `FleaMarket`, then back to `Map`.
- **Boss victory** ends the run with a victory result.
- **Combat defeat** ends the run with a defeat result.
- **Menu/quit from active run phases** abandons the run and deletes the active save without a victory/defeat result.

First-run tutorial bootstraps the same run state but temporarily follows:

`Intro Combat -> FleaMarket tutorial -> DiceSelect tutorial -> Tutorial Combat -> Map`

The intro combat is special-cased while the tutorial intro step is active. After the final tutorial combat completes, the tutorial is inactive and the still-unselected run (`current_node_id == -1`) routes to `Map`.

## Screens

- **MainMenu**: start, continue, settings/tutorial replay, survey, exit, and victory/defeat run result overlay.
- **Map**: generated 10-depth route map with start, combat, shop, and boss nodes. Opens near the next relevant node and persists run state.
- **FleaMarket**: shop plus dice bag management. Used both outside a run and for shop map nodes. Shop-node offerings, sold flags, and reroll count persist on the current `RunState`.
- **DiceSelect**: choose dice from the bag before combat. Active-run menu exits abandon the run.
- **Combat**: roll/hold/reroll/score loop with probability panel, pause/result overlays, tutorial overlay support, and run result resolution.

## Directory Structure

```
project.godot

resources/
  data/
    combos.json                  # combo definitions and scoring rules
    dice_shop.json               # shop catalogue
    faces.json                   # face definitions
    map_config.json              # map depth, node counts, shop chance, boss multiplier

scenes/
  main_menu/
    main_menu.tscn
    main_menu.gd
  map/
    map_screen.tscn              # map UI, edge drawing, scrolling
    map_screen.gd
    map_node_button.tscn         # icon + caption button for map nodes
    map_node_button.gd
  flea_market/
    flea_market_screen.tscn
    flea_market_screen.gd
  dice_select/
    dice_select_screen.tscn
    dice_select_screen.gd
  combat/
    combat_screen.tscn
    combat_screen.gd

scripts/
  autoload/
    game_manager.gd              # phase routing, run state, save/load, wallet, combat results
    data_manager.gd              # JSON loading and validated data access
    tutorial_manager.gd          # tutorial mode, checkpoints, scripted tutorial requirements
    audio_manager.gd             # SFX/music and volume persistence
  map/
    map_generator.gd             # data-driven route generation
    map_node.gd                  # node id/type/depth/edges
    run_state.gd                 # current run graph, progress, shop states
  dice/
    die.gd
    dice_bag.gd
    dice_face.gd
  scoring/
    combo_detector.gd
    combo_odds_helper.gd
    modifier.gd
    scoring_engine.gd
  combat/
    combat_manager.gd
    combat_dice.gd
    combat_probability_panel.gd
  shop/
    shop_generator.gd
  ui/
    pixel_bg.gd
    main_menu_run_result_plan.gd # pure MainMenu run result overlay display rules
    item_card.gd
    shop_item_card.gd
    dice_face_panel.gd
    tutorial_overlay.gd
    combo_reveal_fx.gd
```

## Autoloads

### GameManager (`scripts/autoload/game_manager.gd`)

`GameManager` is the central phase and run-state coordinator.

Key state:

- `current_phase: Phase` — `MAIN_MENU`, `FLEA_MARKET`, `DICE_SELECT`, `COMBAT`, `MAP`.
- `current_run: RunState` — active generated map run, or `null` outside active runs.
- `last_run_result: Dictionary` — transient victory/defeat data rendered by MainMenu.
- `coins`, `dice_bag`, `modifiers`, `selected_dice`, `total_score`, `target_score`, `current_round`, `hands_per_round`, `rerolls_per_hand`.
- `save_path` and save format metadata.

Primary methods:

- `start_game(skip_tutorial_intro := false)` resets state, creates a generated run, and routes either to intro combat or map.
- `start_tutorial_replay()` runs tutorial without keeping the active map run.
- `skip_active_tutorial()` completes tutorial and creates/routes to a normal map run.
- `enter_map_node(node_id)` validates availability, marks the current map node, applies boss target scaling when needed, then routes to dice select or flea market.
- `complete_current_node()` applies combat/shop/boss completion effects and routes to map or run end.
- `end_combat(final_score, target_beaten)` applies combat result state and immediately changes phase.
- `resolve_combat_result_for_overlay(final_score, target_beaten)` applies active-run combat result state and writes/deletes the save while the Combat result overlay remains visible.
- `finish_resolved_combat_result()` changes scene after the player presses the already-resolved result overlay button.
- `flea_market_continue()` completes shop nodes or falls back to dice select outside runs.
- `end_run(victory)` sets `last_run_result`, clears `current_run`, deletes the save, and routes to MainMenu.
- `abandon_run()` clears the active run without result feedback and deletes the save.

Signals:

- `phase_changed(new_phase)`
- `coins_changed(new_amount)`
- `score_changed(new_score)`

### DataManager (`scripts/autoload/data_manager.gd`)

`DataManager` loads and validates JSON gameplay data at boot.

Accessors include:

- `get_all_faces()`, `get_face(id)`
- `get_shop_catalogue()`
- `get_combo_rules()`
- `get_map_config()`

`get_map_config()` validates map settings and falls back to safe defaults when data is invalid.

### TutorialManager (`scripts/autoload/tutorial_manager.gd`)

`TutorialManager` owns first-run and replay tutorial state:

- tutorial mode/completion/checkpoint scene
- current step id
- scripted roll values
- required shop purchases, dice selections, and combat holds
- save/load serialization for tutorial checkpoint persistence

Scene scripts call `TutorialManager.report_action(...)` and `enter_scene(...)` to advance tutorial steps.

## Map And Run Systems

### MapNode (`scripts/map/map_node.gd`)

`MapNode` is a lightweight value object:

- `id`
- `type` — `COMBAT`, `SHOP`, or `BOSS`
- `depth`
- `next_ids`

### RunState (`scripts/map/run_state.gd`)

`RunState` stores one generated map run:

- `nodes: Dictionary`
- `seed: int`
- `current_node_id: int` (`-1` before the first selected node)
- `visited_node_ids`
- `completed_node_ids`
- `shop_states`

It exposes current-node lookup, enter/complete helpers, availability calculation, and per-shop state get/set helpers.

### MapGenerator (`scripts/map/map_generator.gd`)

`MapGenerator.generate(seed, config)` builds a run graph from `resources/data/map_config.json`.

The default map is 10 depths. Depth 1 contains initial choices, the final depth contains a boss, and middle depths mix combat/shop nodes while preserving valid forward edges.

## Save And Load

`GameManager.build_save_data()` writes format-versioned JSON with player state, tutorial state, and `current_run` when present.

Save behavior:

- Non-tutorial `COMBAT` saves normalize to `DICE_SELECT` for active runs, so a mid-combat reload restarts before combat rather than inside a volatile roll state.
- `MAP` without an active run normalizes to `FLEA_MARKET` for legacy compatibility.
- Active run state includes serialized map nodes, current node, visited/completed nodes, and shop states.
- Run victory/defeat and abandon delete the active save so MainMenu cannot continue stale pre-end state.
- Active-run Combat result overlays resolve state immediately: victory writes the next `MAP`/run-end state before the overlay button is pressed; defeat deletes the save and records defeat result data before the overlay button is pressed.

`GameManager.apply_save_data()` migrates old saves to the current format, restores player/run/tutorial state, and returns the phase to load.

## Core Gameplay Systems

### Dice System

- `Die` holds six `DiceFace` instances plus metadata such as color/name/rarity.
- `DiceBag` stores owned dice and supplies draw/get/remove helpers.
- Faces can be swapped in the flea market to alter probability distributions.

### Scoring

- `ComboDetector` identifies the best Yahtzee-style combo for rolled values.
- `ScoringEngine` calculates total score from combo rules, dice faces, dice colors, and active modifiers.
- `ComboOddsHelper` powers combat probability display for current held/unheld dice.

### Combat

`CombatManager` owns the roll/reroll/score loop and emits signals consumed by `CombatScreen`:

- `roll_dice()`
- `toggle_hold(index)`
- `score_hand(modifiers)`
- `combat_ended(final_score, target_beaten)`

`CombatScreen` owns presentation, overlays, animation, tutorial gating, and result-overlay navigation. It delegates durable state changes to `GameManager`.

### Shop

`ShopGenerator` builds randomized offerings from `dice_shop.json`.

`FleaMarketScreen` handles purchases, face swaps, rerolls, tutorial market steps, and persistence of map shop-node state through `RunState.shop_states`.

## Scene Trees

### MainMenu

Control root with pixel background, title, Start/Continue/Settings/Survey/Exit buttons, settings overlay, and run result overlay.

`MainMenuRunResultPlan` owns pure run result overlay display rules: victory/defeat title, summary labels, and continue button copy. `MainMenu` applies the plan to Godot controls and keeps overlay construction local to the scene.

### Map

Pixel background with top bar (`MENU`, title, coins), framed scroll container, generated map node buttons, drawn start/path edges, and automatic scroll-to-relevant-node behavior.

### FleaMarket

Pixel background with top bar, coin display, shop offerings, inventory/dice face management, ready/continue routing, and tutorial overlay integration.

### DiceSelect

Pixel background with dice selection groups, selected dice list, ready/menu controls, and tutorial constraints for required dice.

### Combat

Pixel background with top bar, score/probability surfaces, dice tray, action buttons, hover description panel, combo reveal effects, tutorial overlay, pause overlay, combo overlay, and result overlay.

## Testing Strategy

- `tests/unit`: pure data/model/logic coverage such as map generation, run state, dice, scoring, shop generation, and tutorial manager.
- `tests/integration`: manager and cross-scene run flows, save/load, abandon/end-run behavior, shop persistence, combat result overlay persistence.
- `tests/smoke`: scene instantiation and structural UI checks for main menu, map, combat, tutorial E2E, and layout constraints.

Use `make test` for the full GUT suite, `make static-check` for Godot import/syntax sanity, and `make lint`/`make format-check` for style.

## BASIC4 vs FULL44 Scope

| System | BASIC4 | FULL44 adds |
|--------|--------|-------------|
| Dice | 5 colorless dice, default faces | Larger bag, rarity-driven dice, richer face/modifier pool |
| Flea Market | Fixed/simple catalogue | Randomized stock, rerolls, persistent shop-node state |
| Items | Dice, faces, modifiers | Synergies, rarity tiers, conditional modifiers |
| Combat | Roll + reroll, Yahtzee combos, single target | Escalating targets, probability panel, richer feedback |
| Progression | Single round | 10-depth map run with combat/shop/boss nodes |
| Save/Results | Basic continue | Versioned run saves, victory/defeat overlays, stale-save protection |
| Polish | Placeholder UI | Animations, SFX/music, tutorial, map icons/captions |
