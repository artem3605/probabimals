# BASIC4 — Minimum Viable Version

The smallest playable version of the game that demonstrates the core loop.

## Scope

### Three Screens

1. **MainMenu** — Start and Exit buttons.
2. **FleaMarket** — Simplified shop (fixed catalogue) + dice bag management on one screen.
3. **Combat** — Roll dice, keep/reroll, score combos against a target.

### What's In

1. **5 colorless dice** — each with default faces (1–6).
2. **Simplified flea market** — a fixed catalogue of ~10–12 items (extra dice, replacement faces, modifiers) with coin prices.
3. **Item taxonomy** — three categories:
   - **Dice** — add to the player's bag.
   - **Faces** — swap onto an existing die to change its number distribution.
   - **Modifiers** — global scoring effects (e.g. "pairs score double").
4. **Coin budget** — the player starts with a fixed number of coins. Items have costs.
5. **Dice customization** — player selects a die, then swaps one of its faces with a purchased face.
6. **Combat phase** — roll 5 dice, keep some, reroll the rest (up to 2 rerolls per hand). Multiple hands per round.
7. **Combat end** — combat ends when the player exhausts all hands or beats the target score. A results overlay shows the final score.
8. **Yahtzee-style scoring** — Pair, Two Pair, Three of a Kind, Full House, Small Straight, Large Straight, Four of a Kind, Yahtzee (five of a kind).

### What's Out

- Colored dice and flush combos.
- Randomized flea market stock (fixed catalogue for now).
- Round progression, difficulty scaling.
- Visual polish, animations, sound.
- Meta-progression (unlocks, currency carry-over between games).

## Goal

Validate that the core loop — **buy dice → customize faces → roll combos → beat target score** — is fun and understandable in a single session.

## Deliverable

A single playable session: the player visits the flea market → buys dice and faces → customizes dice → enters combat → rolls combos → sees final result.
