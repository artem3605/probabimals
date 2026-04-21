# Dice visual polish — design

Bring the combat dice closer to the design mockup from the April 2026 Combat Screen redesign (`Probabimals Game Scene.zip` → `combat-screen.jsx` + `combat-centered-v2.jsx`). Three focused visual changes to the existing, working dice system.

## Goals

- Match the "held = lifted card with gold HELD badge" treatment from the mockup.
- Make combo participation more visible via an accent underline bar under each participating die.
- Add a soft radial glow floor under the whole dice tray while a combo is active, tinted by combo priority color.

## Non-goals

- Hover scale-up (1.06).
- Dedicated 6px drop-shadow block behind each die.
- Any changes to dice values, face rendering, or roll logic.
- Changes to how combo accent *colors* are picked (that lives in `combat_screen.gd` already).

## Changes

### 1. Held state — lift + gold badge

- On `set_held(true)`: the whole `CombatDice` card (die + bottom label) tweens up by 18px (EASE_OUT, TRANS_BACK, ~120ms) for a small bounce.
- A gold "HELD" badge appears above the die: gold `StyleBoxFlat` background, 3px dark border, `Press Start 2P` 8px font, letters in dark color, positioned ~16px above the top edge of `main_button`, horizontally centered.
- Bottom label stays as the die's display name (e.g. `BASIC`, `LOADED`) — it no longer flips to "LOCKED".
- On `set_held(false)`: tween back to y=0, hide badge.

### 2. Combo accent underline bar

- When `set_accent(true, color)` is called on a dice card that is **not** selected/held: a horizontal bar appears under the die.
  - Height 6px, width matches the die width.
  - Fill: the accent color. Border: 2px dark.
  - Positioned ~10px below `main_button`'s bottom edge (between the die and the bottom name label). If that conflicts with the bottom label placement, position it as an overlay instead (absolute, below the die, above the label area).
- The existing border-color swap on `main_button` stays — combined, the two cues mirror the mockup's `drop-shadow` glow + underline.
- On `set_accent(false)`: hide the bar.

### 3. Tray radial glow

- A new `Control` sibling to `_dice_container`, inserted as the previous sibling so the dice render on top.
- While combo is active: visible, tinted with `PRIORITY_COLOR(combo.priority)` (the color already computed in `combat_screen.gd` when updating accents).
- Rendered in `_draw()` as 6–8 concentric semi-transparent ellipses forming a stepped radial gradient — the chunky pixel-art look, not a smooth gradient. Center alpha ~0.2, fully transparent at the outer edge.
- Size: ~1.3× the dice container's bounding rect, centered under it.
- Fades in/out via `modulate:a` tween (~200ms) when the combo changes.

## Files touched

- `scripts/combat/combat_dice.gd` — hold lift tween, HELD badge child, accent bar child, stop calling `set_bottom_text("LOCKED", …)`.
- `scripts/ui/item_card.gd` — no structural changes expected; only touched if the accent underline needs a hook. The `set_selected`/`set_accent` API stays.
- `scenes/combat/combat_screen.gd` — create and manage `_dice_glow` sibling, update glow color/visibility next to the existing accent update.
- New: `scripts/ui/dice_tray_glow.gd` — tiny `Control` with `_draw()` drawing the stepped radial gradient and a `set_glow_color(Color)` method.

## Constants

```
HELD_LIFT_PX := 18
HELD_LIFT_DURATION := 0.12
HELD_BADGE_FONT_SIZE := 8
HELD_BADGE_BORDER_WIDTH := 3
HELD_BADGE_OFFSET_Y := -16
ACCENT_BAR_HEIGHT := 6
ACCENT_BAR_BORDER := 2
ACCENT_BAR_TOP_MARGIN := 10
GLOW_STEPS := 7
GLOW_ALPHA_CENTER := 0.2
GLOW_RADIUS_SCALE := 1.3
GLOW_FADE_DURATION := 0.2
```

## Risks

- The accent bar might visually collide with the bottom die-name label — if so, draw it as an absolute overlay between die and label rather than as another vbox child.
- Lifting the whole card may reveal background under the HBoxContainer row — acceptable, the tray felt background shows through.
- Tween on `position.y` must be cancelled on rapid hold/unhold toggles to avoid accumulating offsets — use `kill()` on any previous lift tween before starting a new one, or tween a cached base position.
