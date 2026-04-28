# Modifier Balance System

## Goal

Create a practical balance framework for score modifiers, shop costs, and future simulation tooling. This document is the design source of truth for deciding whether a modifier is too weak, too strong, too cheap, too expensive, or unclear to the player.

The framework is based on the current implementation in:

- `scripts/scoring/scoring_engine.gd`
- `scripts/autoload/game_manager.gd`
- `resources/data/dice_shop.json`
- `resources/data/combos.json`

Current shop balance data uses `rarity` plus `shop_weight` on each `dice_shop.json`
entry. `rarity` describes player-facing tier and `shop_weight` controls how often
the item appears in randomized shop offerings.

## Current Scoring Model

The current score formula is:

```text
total = floor(face_sum * mult * x_mult)
```

Scoring has three layers:

1. `face_sum`: sum of all rolled face contributions, plus any matching `bonus` modifiers.
2. `mult`: the combo's base multiplier, plus face `MULT` effects, plus matching `add_mult` modifiers.
3. `x_mult`: starts at `1.0`, then multiplies face `XMULT` effects and matching `x_mult` modifiers.

Current modifier effect types:

| Effect | Layer | Current behavior |
| --- | --- | --- |
| `bonus` | `face_sum` | Adds `value` when `condition` matches the detected combo type. |
| `add_mult` | `mult` | Adds `value` when `condition` matches the detected combo type. |
| `x_mult` | `x_mult` | Multiplies by `value` when `condition` matches the detected combo type. |
| `add_rerolls` | Utility | Increases `GameManager.rerolls_per_hand` when bought; it is not stored in `GameManager.modifiers`. |

Condition checks are exact today: empty or `always` conditions apply globally, otherwise `condition` must equal the detected `combo_type`. There is no built-in support yet for "or better", thresholds, round number checks, color checks, or probability-based conditions.

Current combo ordering:

| Priority | Type | Name | Base mult |
| --- | --- | --- | --- |
| 0 | `high_card` | High Card | 1.0 |
| 1 | `pair` | Pair | 1.5 |
| 2 | `two_pair` | Two Pair | 2.0 |
| 3 | `three_same` | Three Same | 3.0 |
| 4 | `small_straight` | Small Straight | 3.5 |
| 5 | `full_house` | Full House | 4.0 |
| 6 | `large_straight` | Large Straight | 5.0 |
| 7 | `four_same` | Four Same | 7.0 |
| 8 | `yahtzee` | Yahtzee | 10.0 |

## Balance Goals

Modifiers should be balanced around roles, not only raw power.

Each modifier needs:

- A readable condition that the player can understand before buying.
- A measurable average value over realistic hands.
- A reason to exist compared with other shop items at the same cost.
- A clear timing profile: early stability, mid-run build support, late-run spike, or utility.
- A risk profile: consistent, conditional, rare spike, or build-around.

The target is not perfect equality. A roguelike shop is healthier when some items are situational, some are safe, and some are exciting but risky. The balance problem is to avoid items that are always correct, never correct, or correct only because their tooltip is misleading.

## Core Metrics

Use these metrics when evaluating each modifier.

### Trigger Rate

How often the modifier condition is true on scored hands.

```text
trigger_rate = triggered_hands / scored_hands
```

This is the first number to check for conditional modifiers. A high-value modifier with a very low trigger rate can be fair; a low-value modifier with a high trigger rate can also be fair.

### Average Score Delta

How many points the modifier adds on average across all scored hands.

```text
average_delta = average(score_with_modifier - score_without_modifier)
```

This should be measured over the same dice, same roll policy, same target, and same number of hands.

### Median Score Delta

The typical gain. This protects against misleading averages when a modifier creates rare huge spikes.

```text
median_delta = median(score_with_modifier - score_without_modifier)
```

### Spike Percentiles

Measure the 90th and 95th percentile score deltas.

```text
p90_delta = 90th_percentile(score_with_modifier - score_without_modifier)
p95_delta = 95th_percentile(score_with_modifier - score_without_modifier)
```

These values show whether an item creates exciting bursts or runaway scaling. `x_mult` modifiers should usually show higher spike percentiles than `bonus` or `add_mult` modifiers.

### Win Rate Delta

How much the modifier changes the chance to beat the target score.

```text
win_rate_delta = win_rate_with_modifier - win_rate_without_modifier
```

For run balance, this is often more useful than raw score. A modifier that adds many points after the target is already beaten may be less valuable than a modifier that turns near-losses into wins.

### Cost Efficiency

Score or win-rate value per coin.

```text
score_efficiency = average_delta / cost
win_efficiency = win_rate_delta / cost
```

Use this for rough comparisons, not as an absolute rule. Utility and build-around items often look odd under pure score efficiency.

### Consistency Impact

How much the modifier reduces bad outcomes.

Useful measurements:

```text
low_score_lift = p25_score_with_modifier - p25_score_without_modifier
fail_rate_delta = fail_rate_without_modifier - fail_rate_with_modifier
```

This matters most for rerolls, face-smoothing, and modifiers that help common hands.

## Evaluation Formulas

These formulas are first-pass estimates. They should guide pricing before simulation, not replace simulation.

### `bonus`

Adds directly to `face_sum`.

```text
triggered_delta = bonus_value * mult * x_mult
expected_delta = trigger_rate * triggered_delta
```

Design use: early stability, beginner-friendly items, and common-condition support.

Risk: can become stronger than expected when paired with high `mult` or `x_mult`.

### `add_mult`

Adds to the additive multiplier layer.

```text
triggered_delta = face_sum * add_mult_value * x_mult
expected_delta = trigger_rate * triggered_delta
```

Design use: core scoring modifiers and combo incentives.

Risk: the same `+mult` value is much stronger when average `face_sum` is high. It also becomes much stronger after `x_mult` enters the build.

### `x_mult`

Multiplies the final multiplier layer.

```text
triggered_delta = face_sum * mult * (x_mult * x_mult_value - x_mult)
expected_delta = trigger_rate * triggered_delta
```

Equivalent:

```text
triggered_delta = base_score_before_x_modifier * (x_mult_value - 1)
```

Design use: rare build-arounds and late-run excitement.

Risk: exponential-feeling growth when stacked with strong `face_sum`, `add_mult`, or future retrigger-like effects. These should usually be rarer, more conditional, or more expensive.

### `add_rerolls`

Extra rerolls do not add points directly. They increase choice and consistency by improving the player's chance to reach a better combo.

Estimate through simulation:

```text
reroll_value = average_score_with_extra_reroll - average_score_without_extra_reroll
```

Also track:

```text
combo_upgrade_rate = upgraded_combo_hands / hands_with_extra_reroll
bad_hand_reduction = low_score_hands_without_extra_reroll - low_score_hands_with_extra_reroll
```

Design use: consistency, agency, and support for conditional combo builds.

Risk: it amplifies every future combo-dependent modifier. Its value is low in a weak build and high in a build with strong conditional payoffs.

## Current Item Notes

### Pair Boost

Data:

```json
{
  "id": "pair_boost",
  "name": "Pair Boost",
  "description": "+1 mult on Pairs",
  "rarity": "common",
  "shop_weight": 8,
  "cost": 10,
  "params": {
    "effect": "add_mult",
    "condition": "pair",
    "value": 1.0
  }
}
```

Current actual behavior: `+1 mult` only when the detected combo type is exactly `pair`.

Design decision: keep `Pair Boost` as an exact-pair modifier for the first balance pass. The description now matches the current exact condition behavior.

Balance expectation:

- Exact `pair`: common early-game modifier, likely a stable starter item.
- Pair-or-better would be a different item with much higher trigger rate and a different cost target.

Recommended first decision: keep the exact-pair behavior and evaluate whether its value/cost still makes sense after shop rarity and weighting are added.

### Full House Master

Data:

```json
{
  "id": "full_house_master",
  "name": "Full House Master",
  "description": "+4 mult on Full Houses",
  "rarity": "rare",
  "shop_weight": 3,
  "cost": 30,
  "params": {
    "effect": "add_mult",
    "condition": "full_house",
    "value": 4.0
  }
}
```

Current actual behavior: `+4 mult` on exact `full_house`.

Balance expectation: high payoff, lower trigger rate. This is a build-around item that wants dice/face choices that bias toward duplicates. It was reduced from `+8 mult` after the balance harness showed it heavily outperforming other current modifiers.

Watch metrics:

- Trigger rate with basic dice.
- Trigger rate after buying loaded or duplicated faces.
- Win-rate delta in rounds where the player can reasonably force Full House.

Recommended first decision: keep the reduced `+4 mult`, rare weighting, and higher cost until the next balance run confirms whether it still outperforms other modifiers.

### Reroll Plus

Data:

```json
{
  "id": "reroll_plus",
  "name": "Reroll Plus",
  "description": "+1 reroll per hand",
  "rarity": "uncommon",
  "shop_weight": 5,
  "cost": 25,
  "params": {
    "effect": "add_rerolls",
    "value": 1
  }
}
```

Current actual behavior: immediately increases `GameManager.rerolls_per_hand` by `1` when bought. It is not stored in `GameManager.modifiers`.

Balance expectation: consistency item, not raw scoring item. It should improve low rolls and increase trigger rates for conditional modifiers.

Watch metrics:

- Win-rate delta.
- Low-score lift.
- Change in combo distribution.
- Interaction with `Pair Boost`, `Full House Master`, and `Yahtzee Hunter`.

Recommended first decision: treat this as underpriced if it raises both average score and consistency more than a similarly priced scoring item. It may need a higher cost even when its direct tooltip looks modest.

### Yahtzee Hunter

Data:

```json
{
  "id": "yahtzee_hunter",
  "name": "Yahtzee Hunter",
  "description": "x3 on Yahtzees",
  "rarity": "rare",
  "shop_weight": 2,
  "cost": 34,
  "params": {
    "effect": "x_mult",
    "condition": "yahtzee",
    "value": 3.0
  }
}
```

Current actual behavior: multiplies `x_mult` by `3.0` only on exact `yahtzee`.

Balance expectation: rare spike build-around. With base Yahtzee mult of `10.0`, this can create dramatic scores, but only if the player can make Yahtzee happen often enough.

Watch metrics:

- Trigger rate with basic dice.
- Trigger rate with loaded dice and repeated high faces.
- P95 score delta.
- Whether it is useless unless bought after enough support pieces.

Recommended first decision: keep it rare/expensive and validate whether the game currently offers enough dice crafting support to make it aspirational instead of bait.

## Future Simulation Harness

The balance harness should answer one question at a time: "What changed when this modifier was added?"

### Inputs

Minimum inputs:

- Dice loadout: five selected `Die` definitions or a named preset.
- Combo rules from `resources/data/combos.json`.
- Modifier set: zero or more modifier dictionaries.
- Rerolls per hand.
- Hands per round.
- Target score.
- Number of simulations.
- Random seed.

Useful named presets:

- `basic_start`: five standard dice.
- `loaded_start`: one loaded die plus four standard dice.
- `pair_build`: dice/faces biased toward pairs.
- `full_house_build`: dice/faces biased toward 3+2 outcomes.
- `yahtzee_build`: dice/faces biased toward one repeated value.

### Roll Policy

The first harness does not need perfect player AI. Use deterministic policies that are easy to compare:

1. `score_immediately`: roll once and score.
2. `greedy_best_combo`: after each roll, hold dice belonging to the current best combo and reroll the rest.
3. `target_combo`: hold dice that move toward a configured combo type, such as `full_house` or `yahtzee`.

The policy must be reported with every result. Otherwise two balance reports are not comparable.

### Outputs

For each run group, output:

- `simulations`
- `seed`
- `preset`
- `roll_policy`
- `modifiers`
- `average_score`
- `median_score`
- `p25_score`
- `p90_score`
- `p95_score`
- `win_rate`
- `combo_distribution`
- `modifier_trigger_rates`
- `average_delta_vs_baseline`
- `median_delta_vs_baseline`
- `win_rate_delta_vs_baseline`
- `cost_efficiency`

### Acceptance Criteria

The harness is useful when it can:

- Compare baseline vs one added modifier.
- Produce stable results when rerun with the same seed.
- Show combo distribution changes caused by extra rerolls.
- Flag a modifier whose tooltip condition does not match its actual trigger logic.
- Export or print enough data to paste into a balance spreadsheet.

## Tuning Workflow

Use this loop for each modifier batch.

1. Define the intended role: stable, conditional, spike, build-around, or utility.
2. Estimate rough expected value from trigger rate and layer formula.
3. Simulate baseline vs modifier using at least one basic preset and one synergy preset.
4. Compare average, median, P90/P95, win-rate delta, and cost efficiency.
5. Adjust one variable at a time: value, condition, cost, rarity, or availability timing.
6. Playtest the adjusted item for readability and fun.
7. Record the decision in the item notes before adding more modifiers.

Do not tune only against average score. Average score misses the difference between a reliable item, a high-variance item, and an item that wins only when the run was already winning.

## First Balance Pass Recommendations

Start with small, reversible changes.

1. Keep `Pair Boost` as exact-pair for now; its wording has been aligned with the current condition behavior.
2. Add a `condition_kind` concept only when there are at least two modifiers that need non-exact matching. For now, exact matching is simple and readable.
3. Treat `Reroll Plus` as a high-impact utility item until simulation proves otherwise.
4. Keep `x_mult` effects rare and conditional until the game has enough data on late-run score growth.
5. Do not introduce more modifier effect types until the balance harness can compare current ones.

## Follow-Up Build Plan

After this spec, the next implementation should be a small simulation harness rather than UI.

Recommended first implementation slice:

1. Add a reusable simulation script under `tools/` or `scripts/balance/`.
2. Load combo rules and shop modifier data from existing JSON.
3. Run baseline vs one modifier with fixed seed.
4. Print a compact text report with score distribution, combo distribution, trigger rate, and cost efficiency.
5. Add focused tests for deterministic scoring comparisons and exact condition behavior.

This keeps the first tool small enough to trust while still answering the most important balance questions.
