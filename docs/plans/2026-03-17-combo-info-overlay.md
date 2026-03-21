# Combo Info Overlay

## What Was Built

A reference overlay accessible from the combat screen showing all 9 combo types, their visual dice-grouping patterns, and effective multipliers. Toggled via a "COMBOS" button in the top-right corner or dismissed with Escape.

### UI Elements

- **COMBOS button** — top-right of combat top bar, replaces empty placeholder
- **Full-screen overlay** — dark semi-transparent background (matching pause/result overlay pattern)
- **Combo rows** — one per combo type (High Card → Yahtzee, priority ascending), each containing:
  - Combo name in uppercase (10px pixel font)
  - 5 colored squares showing abstract dice grouping: blue (group A), pink (group B), gray (any), green gradient (sequence)
  - Effective multiplier — shows base + modified value when modifiers apply, color-coded by priority tier
- **Current combo highlight** — blue-tinted background on the row matching the currently detected combo
- **CLOSE button** + Escape key dismissal

### Interaction Rules

- Overlay toggles on COMBOS button press
- Blocked when result or pause overlays are visible
- Escape key priority: combo overlay → pause resume → pause open
- Highlight updates on roll and on overlay open

## Files Changed

- `scenes/combat/combat_screen.gd` — ~120 lines added

## Key Design Decisions

| Decision | Choice | Alternatives Considered |
|----------|--------|------------------------|
| Display mode | Full-screen overlay | Sidebar panel, dropdown, always-visible strip |
| Multiplier source | Inlined `_get_effective_mult()` | Calling ScoringEngine (requires actual dice faces) |
| Pattern data | Hardcoded color arrays | Data-driven from combos.json |
| Combo order | Priority ascending (High Card first) | Descending, grouped by category |

### Why overlay?

Follows the established pause overlay pattern (`_build_pause_overlay`). The user wanted combo info available on demand but not permanently visible, ruling out sidebar or strip approaches.

### Why inline multiplier calculation?

`ScoringEngine.calculate_score()` requires actual rolled dice faces and `in_combo` arrays — it computes the score for a specific hand. The combo overlay needs to show the generic effective multiplier for each combo type regardless of current roll state. A lightweight inline check against `GameManager.modifiers` was simpler and sufficient.

### Why hardcoded patterns?

The 5-square patterns are visual representations of abstract combo structures (e.g. "two matching + three any"), not game data. They never change with balance tuning. Putting them in JSON would add indirection without benefit.

## Known Limitations

- Base multiplier label uses plain text rather than strikethrough — would need RichTextLabel with BBCode for true strikethrough styling
- `_get_effective_mult()` duplicates condition-checking logic from `ScoringEngine._check_condition()` — if modifier conditions evolve, both must be updated
- Modifier condition matching is simplified: checks `"always"`, empty string, or exact combo type match — doesn't handle complex conditions like threshold-based modifiers

## Data Format Changes

None. No JSON schemas were modified.
