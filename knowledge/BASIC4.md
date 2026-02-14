# BASIC4 — Minimum Viable Version

The smallest playable version of the game that demonstrates the core loop.

## Scope

### What's In

1. **Single machine type** — slot machine with 3 reels.
2. **Fixed part pool** — a small, predefined set of parts (no flea market / shopping phase). The player simply assembles a machine from given components.
3. **One combat per round** — the player spins the machine a limited number of times and accumulates a score.
4. **Simple scoring** — straightforward rules for combining reel outcomes into points (e.g. matching symbols = bonus multiplier).

### What's Out

- Flea market browsing / part discovery.
- Multiple machine types or multiple machines per round.
- Opponent / AI enemy.
- Round progression, difficulty scaling.
- Visual polish, animations, sound.
- Meta-progression (unlocks, currency carry-over).

## Goal

Validate that the core mechanic — **building a probabilistic machine from parts and spinning it for score** — is fun and understandable in isolation.

## Deliverable

A single playable session: the player is given parts → assembles a slot machine → spins it → sees a final score.