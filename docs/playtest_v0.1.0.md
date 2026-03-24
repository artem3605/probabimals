# Probabimals Playtest Report v0.1.0

- Build version: `v0.1.0`
- Play URL: `{PLAY_URL}`
- Survey URL: `https://docs.google.com/forms/d/e/1FAIpQLSdgPZ-V4iFnO2e3-gVyw7HGFkA-ByykxrhiCvcnTikyJZTQ5w/viewform?usp=dialog`
- Date: `2026-03-24`
- Facilitator: `TODO`

## Build Summary

- What changed in this version: first versioned build, save-format versioning, and playtest workflow setup
- What you specifically wanted to validate: clarity of the core loop, first-session comprehension, and overall fun for new players
- Known limitations shared with players: first-session onboarding, target-score communication, and upgraded-die readability were still early and likely to change during iteration

## Cold Player 1

- Response timestamp: `2026-03-24 17:50:12`
- Version entered by player: `0.1.0`
- Device / browser: `MacBook, Safari`
- Previous exposure: `No`
- Session length: `10-20 minutes`
- Ratings:
  - Clarity: `4`
  - Fun: `5`
  - Difficulty: `3`
- Most confusing thing: Is the target number precise (e.g. I need to reach exactly 60), or I can get >=60 and still win.
- Favorite moment: The fact that I can buy colorful dices (I like customization) and extend some combo multipliers in shop.
- Prioritized problem: Changing names of modified dices (they are not "basic" anymore) and clarifying possibility to score more than a target number.
- Would play again: `Yes`
- Anything else: I like the concept and haven't played something similar, wait your release on Steam!

## Cold Player 2

- Response timestamp: `2026-03-24 17:59:21`
- Version entered by player: `0.1.0`
- Device / browser: `laptop (macOS), Safari`
- Previous exposure: `No`
- Session length: `5-10 minutes`
- Ratings:
  - Clarity: `4`
  - Fun: `4`
  - Difficulty: `5`
- Most confusing thing: Funny, but I struggled in the very beginning when there was quick guide on how to play. The buttons, that I needed to press to continue, were highlighted but I didn't notice that and tried to figure out why nothing works.
- Favorite moment: I love the animation of dices + the idea of the game itself with freezes for dices on each roll etc.
- Prioritized problem: I would suggest rethinking highlighting in the initial game guide (to make it clearer where to navigate to continue)
- Would play again: `Maybe`
- Anything else: Maybe, it would be nice to have history of rolls/turns in a round, and also if "bonus" dices were a bit more distinguishable (as the red one, but different). Maybe, some indication of what boost it has on the dice (with more detailed explanation on hover)

## Cold Player 3

- Response timestamp: `2026-03-24 18:05:24`
- Version entered by player: `0.1.0`
- Device / browser: `chrome, macbook`
- Previous exposure: `No`
- Session length: `5-10 minutes`
- Ratings:
  - Clarity: `3`
  - Fun: `4`
  - Difficulty: `4`
- Most confusing thing: My first thought was that I needed to score exactly the amount written. Also, it is unclear how many points it is left to earn, what is the expected number of earnings per round (so it is hard to get what is a good turn and what is bad at the beginning)
- Favorite moment: ui is cool, upgrades are also funny
- Prioritized problem: upgrading dices is terrible, when I have 5 Basic dices but slightly different (since I changed them) I have no idea how to quickly distinguish between them
- Would play again: `Yes`
- Anything else: cool game

## Cross-Player Findings

- Shared strengths: Dice animation, the core concept, and the upgrade/customization layer all landed well with first-time players.
- Shared pain points: Players repeatedly struggled with target-score communication, early onboarding clarity, and distinguishing modified or bonus dice once the pool became mixed.
- Version-specific regressions or surprises: Two of three players assumed the target had to be hit exactly, and the current UI did not give enough context to judge round quality, remaining points, or the identity of upgraded dice quickly.

## Next Actions

1. Fix: Make the win condition explicit as `score >= target`, and show remaining points prominently during the round.
2. Re-test: Tutorial progression highlighting and modified-die readability in both the shop and combat flows.
3. Track in next version: Roll or turn history, clearer bonus-die affordances, and richer hover/help text for die boosts.
