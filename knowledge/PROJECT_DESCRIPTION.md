# Project Description

## Overview

**Probabimals** is a round-based dice strategy game inspired by Yahtzee and Balatro. Players collect and customize dice, then roll them in combat to score points through combinations.

## Core Loop

Each round consists of two phases:

### 1. Preparation Phase — "The Flea Market"

- The player visits a **flea market** to buy dice, replacement faces, and modifiers.
- **Dice** go into the player's bag. Each die has 6 faces (default: numbers 1–6).
- **Faces** can be swapped onto existing dice to change their odds (Dice Forge style).
- **Modifiers** are joker-like items that transform scoring rules globally.

### 2. Combat Phase — "The Roll"

- The player rolls 5 dice from their bag.
- After seeing the result, the player may **keep** some dice and **reroll** the rest (up to 2 rerolls).
- The final result is scored based on **combinations** (pairs, straights, full house, etc.).
- Modifiers apply on top, multiplying or transforming the score.
- The goal is to beat the round's **target score** (blind).

## Key Concepts

- **Die** — a six-sided die from the player's bag. Base dice are colorless with faces 1–6. Colored dice are rarer and unlock color-based combos.
- **Face** — a single side of a die. Faces can be swapped at the flea market to change a die's number distribution (e.g. replace a 1-face with a second 6-face).
- **Modifier** — a joker-like item with a global effect on scoring (e.g. "all Full Houses score double", "pairs count as triples"). The primary source of build-defining power.
- **Combo** — a scoring pattern in the rolled dice. Based on Yahtzee: Pair, Two Pair, Three of a Kind, Full House, Small Straight, Large Straight, Four of a Kind, Yahtzee (five of a kind). Colored dice add Flush (5 dice of the same color).
- **Reroll** — the player's tactical tool. After rolling, keep favorable dice and reroll the rest. Limited to 2 rerolls per hand by default.
- **Blind** — the target score the player must beat to advance. Escalates each round.

## Design Pillars

1. **Meaningful randomness** — outcomes are probabilistic, but the player's choices in dice selection and face customization heavily influence the odds.
2. **Dice crafting** — depth comes from discovering synergies between dice, faces, and modifiers to build powerful scoring engines.
3. **Round progression** — each round offers new dice and parts alongside escalating score targets, encouraging adaptation.
