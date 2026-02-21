# Architecture

## Three Screens

- **Screen 1 — MainMenu**: Start and Exit buttons.
- **Screen 2 — FleaMarket**: Simplified shop (fixed catalogue of items) + dice bag management on one screen. Player buys dice, faces, and modifiers. Coin counter. "Combat" button to proceed.
- **Screen 3 — Combat**: The player's dice bag is shown. Player rolls 5 dice, keeps some, rerolls the rest (up to 2 rerolls). Score accumulates across hands. Combat ends when the player exhausts all hands or beats the target score. Results overlay appears with final score.

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
    flea_market_screen.tscn      # shop + dice bag management combined
    flea_market_screen.gd
    shop_item.tscn               # single item card in shop shelf
    shop_item.gd
    die_card.tscn                # die card in bag display
    die_card.gd
    face_slot.tscn               # face slot on a die (for swapping)
    face_slot.gd
  combat/
    combat_screen.tscn           # combat phase UI
    combat_screen.gd
    dice_tray_visual.tscn        # the rolling area showing 5 dice
    dice_tray_visual.gd
    die_visual.tscn              # single die visual (shows face result)
    die_visual.gd

scripts/
  autoload/
    game_manager.gd              # game state, phase transitions, player wallet
    data_manager.gd              # loads & serves JSON data
  dice/
    die.gd                       # single die (RefCounted): holds 6 faces, color
    dice_bag.gd                  # player's bag of dice, draw logic
  scoring/
    scoring_engine.gd            # combo detection + point calculation
    combo_detector.gd            # identifies combos in a set of rolled values
  combat/
    combat_manager.gd            # orchestrates roll-reroll-score loop

assets/
  art/
    dice/                        # die sprites, face icons
    modifiers/                   # modifier card artwork
    ui/                          # buttons, panels, backgrounds
  audio/
    sfx/
    music/
  fonts/

resources/
  data/
    faces.json                   # face definitions (id, value, rarity)
    dice_shop.json               # shop catalogue (dice, faces, modifiers with costs)
    combos.json                  # combo definitions and scoring rules
  themes/
    default_theme.tres
```

---

## Autoloads (Singletons)

### GameManager (`scripts/autoload/game_manager.gd`)

- `current_phase: Phase` — MAIN_MENU, FLEA_MARKET, COMBAT
- `coins: int` — player's currency
- `dice_bag: DiceBag` — player's collection of dice
- `modifiers: Array[Modifier]` — active modifiers
- `total_score: int`
- Signals: `phase_changed`, `coins_changed`, `score_changed`
- Methods: `start_game()`, `go_to_combat()`, `end_combat()`, `buy_item()`, `swap_face()`

### DataManager (`scripts/autoload/data_manager.gd`)

- Loads JSON files at `_ready()`
- `get_all_faces()`, `get_face(id)`, `get_shop_catalogue()`, `get_combo_rules()`
- Pure data accessor — no game logic

---

## Item Taxonomy

### Dice (add to bag)

- **Die** — a six-sided die with customizable faces. Base dice are colorless with default faces 1–6. Colored dice are rarer and enable flush combos.

### Faces (swap onto a die)

- **Face** — replaces one side of a die. Changes the number distribution (e.g. a face with value 6 replaces a face with value 1, making 6 more likely).

### Modifiers (global scoring effects)

- **Score Modifier** — multiplies or transforms scoring (e.g. "Full Houses score double").
- **Combo Modifier** — changes combo rules (e.g. "pairs count as triples").
- **Reroll Modifier** — grants extra rerolls or other roll manipulation.

---

## Core Systems

### Dice System

- `Die` (RefCounted) — holds an array of 6 face values and an optional color. `roll()` returns a random face value (uniform distribution across the 6 faces).
- `DiceBag` (RefCounted) — holds the player's collection of dice. `draw(n)` returns n dice for rolling. Tracks which dice are in the bag.

### Scoring Engine

- `ComboDetector` (RefCounted) — `detect_combos(results: Array[int])` analyzes 5 rolled values and returns the best combo (Pair, Two Pair, Three of a Kind, Full House, Small Straight, Large Straight, Four of a Kind, Yahtzee). With colored dice, also detects Flush.
- `ScoringEngine` (RefCounted) — `calculate_hand_score(combo, values, modifiers)` returns base points, multiplier, and total. Applies active modifiers.

### Combat Manager

- `CombatManager` (Node) — created by CombatScreen. Tracks running score, hands remaining, rerolls remaining.
- `roll_dice()` — rolls all unheld dice, emits `dice_rolled` signal.
- `hold_die(index)` / `unhold_die(index)` — toggles hold state on a die.
- `score_hand()` — evaluates the current roll, scores it, emits `hand_scored` signal.
- `end_combat()` — called by player or auto when all hands exhausted. Emits `combat_ended`.

---

## Data Formats

### faces.json

Each face: `id`, `value` (the number shown), `rarity`, `cost`.

### dice_shop.json

Each shop item: `id`, `name`, `description`, `category` (die/face/modifier), `cost`, `params`.

### combos.json

Combo definitions: `name`, `pattern` (e.g. "three_of_a_kind"), `base_score`, `multiplier`.

---

## Scene Trees (Summary)

### MainMenu
Control root → Background (ColorRect) → CenterContainer → VBoxContainer with Title, StartButton, ExitButton.

### FleaMarket
Control root → Background → MarginContainer → MainVBox:
- TopBar: title, CoinLabel, CombatButton
- ContentSplit (HSplitContainer): ShopPanel (GridContainer of ShopItems) | BagPanel (VBoxContainer showing dice in bag with face details)
- InfoPanel: selected item details, buy/swap buttons

### Combat
Control root → Background → MarginContainer → VBoxContainer:
- HUD: CombatTitle, ScoreLabel, HandsRemainingLabel, RerollsLabel
- DiceTray: HBoxContainer of 5 DieVisuals (clickable to hold/unhold)
- ActionBar: RollButton, ScoreHandButton, EndCombatButton
- ComboLabel: displays detected combo name
- ResultOverlay (ColorRect, initially hidden): FinalScoreLabel, MenuButton

---

## BASIC4 vs FULL44 Scope

| System | BASIC4 | FULL44 adds |
|--------|--------|-------------|
| Dice | 5 colorless dice, default faces | Colored dice, flush combos, larger bag |
| Flea Market | Fixed catalogue, flat coin budget | Randomized stock, scaling prices, rarity tiers |
| Items | ~10–12 items: dice, faces, modifiers | Large pool, synergies, conditional modifiers |
| Combat | Roll + reroll, Yahtzee combos, single target score | Escalating blinds, rich modifier interactions |
| Progression | Single round | 5–7 rounds, persistent inventory, difficulty scaling |
| Polish | Placeholder art, no sound | Animations, SFX, music, tutorial |
