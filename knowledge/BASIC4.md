# BASIC4 — Minimum Viable Version

The smallest playable version of the game that demonstrates the core loop.

## Scope

### Three Screens

1. **MainMenu** — Start and Exit buttons.
2. **FleaMarket** — Simplified shop (fixed catalogue) + machine assembly on one screen.
3. **Combat** — Assembled machines on a field; click to spin; score accumulates.

### What's In

1. **Single machine type** — slot machine with 3 reels.
2. **Simplified flea market** — a fixed catalogue of ~10-12 parts with coin prices. The player buys parts and assembles machines on the same screen.
3. **Part taxonomy** — two categories:
   - **Structural parts** (Frame, Reel, Lever) — define the machine. A slot machine needs 1 frame + 3 reels + 1 lever to be functional.
   - **Modifier parts** (Symbol Injector, Weight Shifter, Score Multiplier) — tune probabilities and scoring.
4. **Coin budget** — the player starts with a fixed number of coins (50). Parts have costs.
5. **Machine assembly** — player places a Frame on the field to create a machine, then attaches Reels, Levers, and Modifiers.
6. **Combat phase** — the player clicks a machine to spin it. Each machine has a limited number of spins (determined by its Levers). Score accumulates across all spins.
7. **Combat end** — combat ends when the player clicks "End Combat" or all spins on all machines are exhausted. A results overlay shows the final score.
8. **Simple scoring** — 3 of a kind and 2 of a kind matches, with symbol values and optional score multipliers from modifiers.

### What's Out

- Randomized flea market stock (fixed catalogue for now).
- Multiple machine types (only slot machines).
- Opponent / AI enemy / target score.
- Round progression, difficulty scaling.
- Visual polish, animations, sound.
- Meta-progression (unlocks, currency carry-over between games).

## Goal

Validate that the core loop — **buy parts → assemble a machine → spin it for score** — is fun and understandable in a single session.

## Deliverable

A single playable session: the player visits the flea market → buys parts with coins → assembles a slot machine → enters combat → spins for score → sees final result.
