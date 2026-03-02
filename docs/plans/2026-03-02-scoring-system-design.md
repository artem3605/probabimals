# Scoring System Design — "Forge"

## Overview

A layered scoring system inspired by Balatro's depth but built natively for dice crafting. Players build a scoring engine by customizing die faces and collecting modifiers. The system produces explosive number growth through multiplicative stacking while keeping each hand a tactical puzzle.

## Core Formula

```
Total = Floor(Face_Sum × Mult × X_Mult)
```

### Layer 1 — Face_Sum (base points)

Sum of all 5 dice face scores, including bonuses and trigger effects:

```
Face_Sum = Σ(face.value + face.bonus + face.trigger_bonus) + Σ(bonus_modifier_bonuses)
```

All 5 dice contribute, not just those in the combo. Faces "in combo" and "off combo" may trigger different effects.

### Layer 2 — Mult (combined multiplier)

Combo multiplier plus all additive mult sources:

```
Mult = Combo_Mult + Σ(face_+mult) + Σ(modifier_+mult)
```

Linear growth — reliable and predictable.

### Layer 3 — X_Mult (exponential multiplier)

All multiplicative mult sources multiply together:

```
X_Mult = 1.0 × Π(face_×mult) × Π(modifier_×mult) × elemental_bonus
```

Exponential growth — rare, expensive sources. This is where scores explode.

## Combo Table

### Standard Combos (BASIC4 + FULL44)

| Priority | Combo            | Pattern                | Combo Mult |
|----------|------------------|------------------------|------------|
| 0        | High Card        | No matches             | ×1         |
| 1        | Pair             | 2 matching             | ×1.5       |
| 2        | Two Pair         | 2+2 matching           | ×2         |
| 3        | Three of a Kind  | 3 matching             | ×3         |
| 4        | Small Straight   | 4 sequential           | ×3.5       |
| 5        | Full House       | 3+2 matching           | ×4         |
| 6        | Large Straight   | 5 sequential           | ×5         |
| 7        | Four of a Kind   | 4 matching             | ×7         |
| 8        | Yahtzee          | 5 matching             | ×10        |

### Extended Combos (FULL44 only)

| Priority | Combo              | Pattern                            | Combo Mult |
|----------|--------------------|------------------------------------|------------|
| 9        | Flush              | 5 same-color dice                  | ×4         |
| 10       | Full House Flush   | Full House + all same color        | ×6         |
| 11       | Straight Flush     | Large Straight + all same color    | ×8         |

Best combo wins when multiple patterns match. Wild Faces assume the value that produces the highest-priority combo.

## Face Types

Each face has: **value** (0–6), **effect** (optional), **element** (optional, FULL44).

### Basic Face
- Value: 1–6, no effect
- Starting faces on all dice

### Pip Face
- Value: 1–6 + bonus points to Face_Sum
- Does not change value for combo detection
- Example: `{value: 5, effect: "+8 bonus"}` → contributes 13 to Face_Sum

### Mult Face
- Value: usually low (1–3), adds to Mult
- Example: `{value: 2, effect: "+3 mult"}` → contributes 2 to Face_Sum, adds 3 to Mult
- Trade-off: low base value for multiplier power

### XMult Face
- Value: low (1–2), provides ×mult
- Example: `{value: 1, effect: "×2"}` → contributes 1 to Face_Sum, doubles X_Mult
- Very rare and expensive. Primary exponential growth on faces.

### Wild Face
- Value: 0, counts as any number for combo detection
- Chooses value producing the best combo
- Adds 0 to Face_Sum — sacrifices base for combo flexibility

### Trigger Face (FULL44 only)
- Value: 2–5, conditional effect based on combo type or hand state
- Examples:
  - `{value: 3, effect: "if Three of a Kind: +15 bonus"}`
  - `{value: 4, effect: "if in combo: +2 mult"}`
  - `{value: 2, effect: "if NOT in combo: ×1.5"}`
- Enables build-around strategies targeting specific combos

### Elemental Face (FULL44 only)
- Value: 2–5, has an element tag (Fire, Ice, Nature, Shadow)
- When 3+ same-element faces appear in one hand → bonus ×mult:
  - 3 matching: ×1.5
  - 4 matching: ×2
  - 5 matching: ×3
- Long-term investment strategy

### Scope Split

| Type      | BASIC4           | FULL44          |
|-----------|------------------|-----------------|
| Basic     | Yes              | Yes             |
| Pip       | Yes (2–3 items)  | Yes (expanded)  |
| Mult      | Yes (2 items)    | Yes (expanded)  |
| XMult     | Yes (1 item)     | Yes (expanded)  |
| Wild      | Yes (1 item)     | Yes             |
| Trigger   | No               | Yes (5+ items)  |
| Elemental | No               | Yes (4 elements)|

## Modifier System

Modifiers are joker-like items bought at the Flea Market. They persist for the entire run and transform scoring.

### Slots
- BASIC4: max 3 modifiers
- FULL44: max 5 modifiers
- Selling returns 50% cost (rounded down)

### Modifier Categories

#### 1. Mult Modifiers (+mult)

| Name          | Effect   | Condition                        | Cost | Rarity   |
|---------------|----------|----------------------------------|------|----------|
| Steady Hand   | +2 mult  | Always                           | 15   | Common   |
| Pair Lover    | +4 mult  | If combo is Pair or better       | 20   | Common   |
| Triple Threat | +6 mult  | If combo is Three of a Kind+     | 30   | Uncommon |
| Full House Fan| +8 mult  | If combo is Full House           | 35   | Uncommon |

#### 2. XMult Modifiers (×mult)

| Name           | Effect | Condition                    | Cost | Rarity   |
|----------------|--------|------------------------------|------|----------|
| Score Master   | ×2     | Always                       | 60   | Rare     |
| Yahtzee Hunter | ×3     | If combo is Yahtzee          | 50   | Rare     |
| High Roller    | ×2     | If Face_Sum > 20             | 45   | Uncommon |

#### 3. Bonus Modifiers (bonus to Face_Sum)

| Name           | Effect          | Condition          | Cost | Rarity   |
|----------------|-----------------|--------------------|------|----------|
| Loaded Dice    | +10 Face_Sum    | Always             | 20   | Common   |
| Pair Bonus     | +15 Face_Sum    | If Pair            | 25   | Common   |
| Straight Arrow | +20 Face_Sum    | If any Straight    | 30   | Uncommon |

#### 4. Utility Modifiers

| Name         | Effect                                           | Cost | Rarity   |
|--------------|--------------------------------------------------|------|----------|
| Reroll Plus  | +1 reroll per hand                               | 25   | Common   |
| Extra Hand   | +1 hand per round                                | 50   | Rare     |
| Wild Card    | One random face becomes Wild for combat duration | 35   | Uncommon |

#### 5. Synergy Modifiers (FULL44 only)

| Name                 | Effect                                            | Cost | Rarity    |
|----------------------|---------------------------------------------------|------|-----------|
| Face Collector       | +1 mult per unique Pip Face in bag                | 40   | Uncommon  |
| Elemental Master     | ×1.5 per complete element set (all 4 elements)    | 55   | Rare      |
| Trigger Happy        | All Trigger Faces activate twice                  | 70   | Legendary |
| Loaded Bag           | +2 Face_Sum per die in bag beyond 5               | 30   | Uncommon  |
| Multiplier Cascade   | Each ×mult source also adds +1 mult               | 65   | Legendary |

### Rarity Distribution in Shop

| Rarity    | Shop chance | Power level       |
|-----------|-------------|-------------------|
| Common    | 60%         | Moderate          |
| Uncommon  | 25%         | Noticeable        |
| Rare      | 12%         | Strong            |
| Legendary | 3%          | Build-defining    |

### BASIC4 Modifier Subset
6–8 modifiers from categories 1–4 (no Synergy). Common and Uncommon only. Max 3 slots.

## Scoring Flow

Step-by-step procedure when a hand is scored:

### Step 1 — Detect Combo
1. Collect values from all 5 dice (face.value)
2. If Wild Faces present: enumerate all possible values (1–6) for each Wild, find best combo
3. Select highest-priority combo
4. Mark each die as "in combo" or "off combo"

### Step 2 — Compute Face_Sum
For each of the 5 dice:
1. Start with `face.value`
2. Add `face.bonus` (Pip Face bonus)
3. Evaluate trigger conditions:
   - "In combo" → fire in-combo triggers
   - "Off combo" → fire off-combo triggers
   - Check combo-type conditions, threshold conditions, etc.
4. Add `trigger_bonus`
5. Sum all 5 face scores
6. Apply Bonus Modifiers (Loaded Dice, Pair Bonus, etc.)

### Step 3 — Compute Mult
1. Start with `Combo_Mult` (from combo table)
2. Add +mult from faces (Mult Face, triggered +mult)
3. Add +mult from modifiers (Steady Hand, Pair Lover, etc.)
4. Add +mult from Synergy Modifiers

### Step 4 — Compute X_Mult
1. Start with `1.0`
2. Multiply by ×mult from faces (XMult Face)
3. Multiply by ×mult from modifiers (Score Master, Yahtzee Hunter, etc.)
4. Multiply by Elemental bonuses (3+ same element)

### Step 5 — Final Calculation
```
Total = Floor(Face_Sum × Mult × X_Mult)
```

### Step 6 — Display
Show breakdown: `Face_Sum [20] × Mult [4.5] × X_Mult [×2] = 180`
Highlight contributing faces and modifiers.

## Late-Game Example

Roll: [6, 6, 6, 6, Wild]. Combo: **Yahtzee** (Wild = 6).

Faces:
- Die 1: Pip Face `{value: 6, bonus: +8}` → 14
- Die 2: Mult Face `{value: 6, effect: "+4 mult"}` → 6
- Die 3: XMult Face `{value: 6, effect: "×2"}` → 6
- Die 4: Trigger Face `{value: 6, effect: "if Yahtzee: +20 bonus"}` → 26
- Die 5: Wild Face `{value: 0}` → 0

Modifiers: Loaded Dice (+10), Yahtzee Hunter (×3), Score Master (×2)

Calculation:
- Face_Sum = 14 + 6 + 6 + 26 + 0 + 10 = **62**
- Mult = 10 + 4 = **14**
- X_Mult = 1 × 2 × 3 × 2 = **12**
- **Total = 62 × 14 × 12 = 10,416**

## Data-Driven Architecture

All scoring data lives in JSON files, not hardcoded:

- `faces.json` — face definitions: id, value, effect_type, effect_value, effect_condition, element, cost, rarity
- `combos.json` — combo definitions: name, pattern, combo_mult, priority
- `modifiers.json` — modifier definitions: name, effect_type, effect_value, condition, cost, rarity, category

The scoring engine reads from these files and evaluates generically. Changing balance requires editing JSON, not code.

## BASIC4 vs FULL44 Summary

| System       | BASIC4                              | FULL44                                    |
|--------------|-------------------------------------|-------------------------------------------|
| Formula      | Full (3 layers)                     | Full (3 layers)                           |
| Face types   | Basic, Pip, Mult, XMult, Wild       | + Trigger, Elemental                      |
| Combos       | 9 standard                          | + Flush, Full House Flush, Straight Flush |
| Modifiers    | 6–8 (Common/Uncommon), 3 slots      | 20+ (all rarities), 5 slots              |
| Shop         | Fixed catalogue                     | Randomized with rarity weights            |
| Progression  | Single round                        | 5–7 rounds, escalating blinds            |
