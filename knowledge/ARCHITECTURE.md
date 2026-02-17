# Architecture

## Three Screens

- **Screen 1 — MainMenu**: Start and Exit buttons.
- **Screen 2 — FleaMarket**: Simplified shop (fixed catalogue of parts) + machine assembly field on one screen. Player buys parts, places machine bases on the field, inserts structural parts (lever, reels) into them. Coin counter. "Combat" button to proceed.
- **Screen 3 — Combat**: The assembled machines are shown on the field. Player clicks any machine to spin it. Each machine has a limited number of spins (determined by its parts). Score accumulates across all spins. Combat ends when player clicks "End Combat" or all spins are exhausted. Results overlay appears with final score.

**Flow:** MainMenu → FleaMarket → Combat → MainMenu (FULL44 adds: Combat → FleaMarket for next round).

---

## Directory Structure

```
project.godot

scenes/
  main_menu/
    main_menu.tscn               # Start / Exit screen
    main_menu.gd
  flea_market/
    flea_market_screen.tscn      # shop + assembly combined
    flea_market_screen.gd
    shop_item.tscn               # single item card in shop shelf
    shop_item.gd
    part_card.tscn               # part card in hand
    part_card.gd
    machine_slot.tscn            # slot on the field for a machine
    machine_slot.gd
  combat/
    combat_screen.tscn           # combat phase UI
    combat_screen.gd
    slot_machine_visual.tscn     # clickable machine during combat
    slot_machine_visual.gd
    reel_visual.tscn             # single reel column visual
    reel_visual.gd

scripts/
  autoload/
    game_manager.gd              # game state, phase transitions, player wallet
    data_manager.gd              # loads & serves JSON data
  machines/
    machine.gd                   # base class (RefCounted)
    slot_machine.gd              # 3-reel slot: holds reels, spins_remaining
    reel.gd                      # weighted symbol pool, spin logic
  parts/
    part_data.gd                 # custom Resource: name, cost, type, effect
    part_effect.gd               # applies a part's effect to a machine
  scoring/
    scoring_engine.gd            # match detection + point calculation
  combat/
    combat_manager.gd            # orchestrates spin-resolve-score loop

assets/
  art/
    symbols/                     # 128×128 PNG per symbol
    machines/                    # machine frame, reel bg, payline
    parts/                       # part card artwork
    ui/                          # buttons, panels, backgrounds
  audio/
    sfx/
    music/
  fonts/

resources/
  data/
    symbols.json                 # symbol definitions (id, name, weight, value)
    parts.json                   # part definitions (id, name, type, cost, params)
    scoring_rules.json           # match multipliers
  themes/
    default_theme.tres
```

---

## Autoloads (Singletons)

### GameManager (`scripts/autoload/game_manager.gd`)

- `current_phase: Phase` — MAIN_MENU, FLEA_MARKET, COMBAT
- `coins: int` — player's currency
- `hand: Array[PartData]` — purchased parts not yet placed
- `machines: Array[Machine]` — assembled machines on the field
- `total_score: int`
- Signals: `phase_changed`, `coins_changed`, `score_changed`
- Methods: `start_game()`, `go_to_combat()`, `end_combat()`, `buy_part()`, `create_machine()`, `attach_part_to_machine()`

### DataManager (`scripts/autoload/data_manager.gd`)

- Loads JSON files at `_ready()`
- `get_all_symbols()`, `get_symbol(id)`, `get_all_parts()`, `get_scoring_rules()`, `get_shop_catalogue()`
- Pure data accessor — no game logic

---

## Part Taxonomy

### Structural Parts (build the machine)

- **Frame** — the machine body; placing a frame on the field creates a machine slot.
- **Reel** — a spinning drum with default symbols. A slot machine needs exactly 3 reels.
- **Lever** — activator; determines how many spins the machine gets.

### Modifier Parts (tune the machine)

- **ADD_SYMBOL** — adds extra copies of a specific symbol to reels.
- **CHANGE_WEIGHT** — changes probability distribution of a symbol.
- **SCORE_MULTIPLIER** — multiplies points from this machine.

---

## Core Systems

### Machine System

- `Machine` (RefCounted) — base class. Holds frame, reels, levers, modifiers. Tracks `spins_remaining`. `is_complete()` checks frame + 3 reels + 1 lever.
- `SlotMachine` extends `Machine` — `spin()` returns array of 3 symbol IDs via weighted random picks from reels.
- `Reel` (RefCounted) — maintains `base_symbol_weights` and `bonus_weights`. `spin()` does a weighted random pick from effective weights.

### Scoring Engine

- `ScoringEngine` (RefCounted) — `calculate_spin_score(results, machine)` returns base points, multiplier, total, and match details.
- Rules: 3-of-a-kind → symbol value × 3.0, 2-of-a-kind → symbol value × 1.0, then apply machine score multiplier.

### Combat Manager

- `CombatManager` (Node) — created by CombatScreen. Tracks running score and active state.
- `spin_machine(machine)` — resolves a spin, scores it, emits `machine_spun` signal.
- `end_combat()` — called by player or auto when all spins exhausted. Emits `combat_ended`.

---

## Data Formats

### symbols.json

Each symbol: `id`, `name`, `weight` (reel probability), `value` (base score).

### parts.json

Each part: `id`, `name`, `description`, `category` (structural/modifier), `type` (FRAME/REEL/LEVER/ADD_SYMBOL/CHANGE_WEIGHT/SCORE_MULTIPLIER), `cost`, `params`.

### scoring_rules.json

Multipliers: `three_of_a_kind_multiplier`, `two_of_a_kind_multiplier`, `no_match_points`.

---

## Scene Trees (Summary)

### MainMenu
Control root → Background (ColorRect) → CenterContainer → VBoxContainer with Title, StartButton, ExitButton.

### FleaMarket
Control root → Background → MarginContainer → MainVBox:
- TopBar: title, CoinLabel, CombatButton
- ContentSplit (HSplitContainer): ShopPanel (GridContainer of ShopItems) | FieldPanel (VBoxContainer of MachineSlots)
- HandPanel: HBoxContainer of PartCards

### Combat
Control root → Background → MarginContainer → VBoxContainer:
- HUD: CombatTitle, ScoreLabel, EndCombatButton
- ScrollContainer → CombatMachineField (VBoxContainer of SlotMachineVisuals)
- ResultOverlay (ColorRect, initially hidden): FinalScoreLabel, MenuButton

---

## BASIC4 vs FULL44 Scope

| System | BASIC4 | FULL44 adds |
|--------|--------|-------------|
| Machines | 1 slot machine (supports multiple architecturally) | Multiple types, multiple per round |
| Flea Market | Fixed catalogue, flat coin budget | Randomized stock, scaling prices, rarity tiers |
| Parts | ~10-12 items, structural + simple modifiers | Large pool, synergies, triggers, conditionals |
| Combat | Click-to-spin, manual/auto end | Opponent target score, consequences |
| Progression | Single round | 5-7 rounds, persistent inventory, difficulty scaling |
| Polish | Placeholder art, no sound | Animations, SFX, music, tutorial |
