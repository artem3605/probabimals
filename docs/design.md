# Game Concept Preparation

## Overview

**Probabimals** — round-based strategy game centered around building probabilistic machines and leveraging their outcomes in combat.

**Core Loop:** buy parts at the flea market → assemble probabilistic machines → spin them in combat for score.

**Design Pillars:**

1. **Meaningful randomness** — outcomes are probabilistic, but the player's choices in preparation heavily influence the odds.
2. **Build crafting** — depth comes from discovering synergies between parts and optimizing machine configurations.
3. **Round progression** — each round offers new parts and escalating challenges, encouraging adaptation.

---

## 1. Team

| Name             | Roles                                                      |
|------------------|------------------------------------------------------------|
| Artem Abaturov   | Game design, Programming, Project Management               |
| Sofia Petrenko   | Art & Visual Design, Programming, Audio, QA & Playtesting  |

### Responsibility Areas

- **Game Design** — core mechanics (probability systems, scoring, synergies), part/component design, balance and tuning, round progression.
- **Programming** — game logic (assembly, spin resolution, score calculation), UI implementation, animations/VFX, data architecture, audio integration.
- **Art & Visual Design** — UI/UX layouts and wireframes, sprite art (parts, machines, symbols), visual effects, fonts and color palette.
- **Audio** — SFX (mechanical spins, clicks, jingles), ambient sounds, music.
- **Project Management** — task tracking, milestone planning (BASIC4 → FULL44), playtesting coordination.
- **QA & Playtesting** — bug reporting, balance testing, UX testing.

---

## 2. Tech

### Engine

**Godot 4.x** with **GDScript**

**Why Godot:**

- Free and open-source — no licensing fees or revenue share.
- Best-in-class 2D engine — ideal for a UI-heavy game with slot machines, drag-and-drop assembly, and card-like part displays.
- Built-in visual editor — scenes, animations, particles, and UI layouts are created visually.
- Signal system — native event-driven architecture, perfect for "reel stopped → calculate result → play animation" flows.
- One-click export — builds for Windows, macOS, Linux (and optionally web/mobile).
- Lightweight — ~40 MB engine, fast iteration cycle.

**Why GDScript:**

- Python-like syntax — low barrier to entry.
- First-class Godot integration — autocomplete, debugger, profiler out of the box.
- Sufficient for the project's complexity.

### Target Platform

- **Primary:** Desktop (Windows, macOS, Linux)
- **Stretch:** Web export (HTML5)

### Project Structure

```
project.godot

scenes/
  main_menu/
  flea_market/
  combat/

scripts/
  autoload/           # GameManager, DataManager
  machines/           # machine.gd, slot_machine.gd, reel.gd
  parts/              # part_data.gd, part_effect.gd
  scoring/            # scoring_engine.gd
  combat/             # combat_manager.gd

assets/
  art/                # symbols, machines, parts, ui
  audio/              # sfx, music
  fonts/

resources/
  data/               # symbols.json, parts.json, scoring_rules.json
  themes/             # default_theme.tres
```

### Version Control

- Git with `.gitignore` tailored for Godot (ignore `.godot/` cache directory).
- Knowledge docs in `knowledge/`, consolidated design in `docs/`.

---

## 3. Game Idea

### Core Loop

Each round consists of two phases:

**Phase 1 — Preparation ("The Flea Market"):**
- The player visits a flea market filled with parts and components.
- Parts can be assembled into probabilistic machines (e.g. slot machines).
- Parts are divided into **structural** (build the machine) and **modifier** (tune its behavior) categories.

**Phase 2 — Combat ("The Spin"):**
- The player activates their assembled machines.
- Each machine can be activated a limited number of times per round (determined by Levers).
- Outcomes of all machines are combined to produce a final combat score.

### Key Concepts

- **Structural Parts** — Frame (machine body), Reel (spinning drum with symbols), Lever (activator granting spins). Required to build a functional machine.
- **Modifier Parts** — Symbol Injector (adds symbol weight), Weight Shifter (changes probability), Score Multiplier (boosts points). Applied on top to tune the machine.
- **Probabilistic Machines** — player-built devices producing random outcomes; slot machine is the primary archetype. Assembled from Frame + 3 Reels + at least 1 Lever.
- **Activation Limit** — number of uses per combat phase; governed by Lever parts.
- **Score Combination** — system for aggregating individual machine results into a final combat score.

---

### 3a. BASIC4 — Minimum Viable Version

The smallest playable version that demonstrates the core loop.

**Goal:** Validate that **buy parts → assemble a machine → spin it for score** is fun and understandable in a single session.

#### Three Screens

1. **MainMenu** — Start and Exit buttons.
2. **FleaMarket** — Simplified shop (fixed catalogue) + machine assembly on one screen.
3. **Combat** — Assembled machines on a field; click to spin; score accumulates.

#### What's In

| Feature | Details |
|---------|---------|
| Machine type | Single slot machine with 3 reels |
| Flea market | Fixed catalogue of ~10–12 parts with coin prices |
| Part taxonomy | Structural (Frame, Reel, Lever) + Modifier (Symbol Injector, Weight Shifter, Score Multiplier) |
| Coin budget | Player starts with 50 coins; parts have costs |
| Assembly | Place Frame on field → attach Reels, Levers, Modifiers |
| Combat | Click machine to spin; limited spins per machine; score accumulates |
| Combat end | Player clicks "End Combat" or all spins exhausted; results overlay with final score |
| Scoring | 3-of-a-kind and 2-of-a-kind matches, symbol values, optional multipliers |

#### What's Out

- Randomized flea market stock
- Multiple machine types
- Opponent / AI / target score
- Round progression, difficulty scaling
- Visual polish, animations, sound
- Meta-progression (unlocks, carry-over)

#### Deliverable

A single playable session: flea market → buy parts → assemble slot machine → combat → spin for score → final result.

---

### 3b. FULL44 — Demo Version

The complete demo experience showcasing all core systems across multiple rounds.

**Goal:** Deliver a polished demo playable for 15–30 minutes, demonstrating the full preparation → combat loop.

#### Flea Market

- Randomized selection of parts each round.
- Multiple part categories with different rarities and effects.
- Limited budget per round, forcing meaningful choices.
- Persistent part inventory across rounds.

#### Machine Building

- Multiple machine types (slot machine + at least one alternative: coin flipper, dice roller, roulette wheel).
- Multiple machines per round.
- Part synergies — certain combos unlock bonus effects.
- Visible machine stats (activation limit, expected value, variance).

#### Combat

- Distinct activation limits per machine.
- Rich score combination (additive, multiplicative, conditional bonuses).
- AI-generated target score scaling with round number.
- Clear feedback on each spin result and running total.

#### Progression

- 5–7 rounds with escalating difficulty.
- Flea market evolution — rarer/more powerful parts in later rounds.
- Win/loss conditions — survive all rounds to win; losing has consequences (lost parts, reduced budget).

#### Polish

- Animations — spinning reels, part assembly, score tallying.
- Sound design — mechanical sounds, market ambiance, victory/defeat cues.
- UI/UX — intuitive drag-and-drop, clear info hierarchy.
- Tutorial — guided first round.

#### Deliverable

Self-contained demo: multiple rounds of shopping → assembly → combat with escalating challenge, ending in win or loss.

---

## Scope Comparison: BASIC4 vs FULL44

| System | BASIC4 | FULL44 adds |
|--------|--------|-------------|
| Machines | 1 slot machine | Multiple types, multiple per round |
| Flea Market | Fixed catalogue, flat coin budget | Randomized stock, scaling prices, rarity tiers |
| Parts | ~10–12 items, structural + simple modifiers | Large pool, synergies, triggers, conditionals |
| Combat | Click-to-spin, manual/auto end | Opponent target score, consequences |
| Progression | Single round | 5–7 rounds, persistent inventory, difficulty scaling |
| Polish | Placeholder art, no sound | Animations, SFX, music, tutorial |
