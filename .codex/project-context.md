# Probabimals Project Context

This file provides the fixed repository context for the Codex-native harness. Read it before planning or implementing any run in this repo.

## Read Order

1. `.codex/project-context.md`
2. `knowledge/PROJECT_DESCRIPTION.md`
3. `knowledge/ARCHITECTURE.md`
4. `knowledge/HOW_TO_RUN.md`
5. `README.md`
6. Relevant source, scene, data, and test files for the active slice

## Repository Purpose

Probabimals is a round-based dice strategy game inspired by Yahtzee and Balatro. Players collect and customize dice in a flea market, then roll and reroll dice in combat to beat escalating score targets through probability-aware combo play.

## Stack And Boundaries

- Engine: Godot 4.x
- Language: GDScript
- Test framework: GUT, vendored under `addons/gut`
- Runtime surfaces: Godot editor/native play and Web export
- Core game data: JSON files under `resources/data/`
- Product and project docs: `knowledge/`, `docs/`, `README.md`, `how_to_run.md`

Current repo boundaries:

- Scenes live under `scenes/`
- Runtime scripts live under `scripts/`
- Data resources live under `resources/data/`
- Tests live under `tests/unit`, `tests/integration`, and `tests/smoke`
- Build/export outputs live under `build/` and should not be treated as source
- Codex harness prompts and templates live under `.codex/harness/`
- Per-run harness artifacts live under `.codex/runs/` and are local/ignored

## Default Working Assumptions

- Prefer the existing Godot/GDScript architecture over introducing new infrastructure.
- Do not add git automation, branching, or commits as part of a harness run.
- Preserve existing gameplay rules unless the active slice intentionally changes them.
- Keep feature slices vertical and player-visible where possible.
- Use existing signals, managers, scene patterns, data files, and tests before adding new abstractions.
- Avoid unrelated visual redesign, broad refactors, or generated asset churn unless the request clearly requires it.
- Update docs only when setup, architecture, gameplay behavior, or verification expectations change meaningfully.

## Vertical Slice Expectations

- A good backlog item changes the smallest end-to-end surface that delivers an observable gameplay or tooling outcome.
- Prefer slices that connect the relevant layers, for example data plus domain logic plus UI plus tests, instead of finishing one technical layer in isolation.
- Keep slice scope narrow enough for one contract, one implementation pass, and one QA pass.
- If a visual or feel requirement cannot be fully judged headlessly, pair structural automated checks with an explicit manual/editor verification note.

## Current Verification Matrix

Use the strongest safe checks available for the files touched in the active slice.

### Godot Import And Script Sanity

- General import/syntax check after scene, resource, or GDScript changes:

```bash
godot --headless --import
```

### Automated Tests

- Primary check after gameplay, manager, UI, data, or test changes:

```bash
./scripts/test/run_gut.sh
```

- Optional JUnit output when useful for CI-style inspection:

```bash
GUT_JUNIT_XML=build/test-results/gut.xml ./scripts/test/run_gut.sh
```

### Web Export

- Use when export configuration, web build behavior, or browser-facing integration is part of the slice:

```bash
godot --headless --export-release "Web Dev" /tmp/probabimals-web-dev/probabimals-dev.html
```

### Manual Or Browser Checks

- Use editor, native play, or browser checks only when the contract explicitly depends on presentation, input feel, layout, animation, or export behavior.
- If a criterion depends on subjective visual feel or unavailable services/tools, mark it as manual, unverified, or blocked rather than guessing.

## Known Repo Gaps Relevant To Harness

- Subjective animation quality, game feel, and visual polish cannot be fully proven by headless GUT tests.
- Web export checks can be slower than logic tests and should be reserved for slices that actually affect export/runtime packaging.
- Browser smoke testing requires a served export and should be declared explicitly in the sprint contract when needed.

## Preferred Planning Heuristics

- Use `knowledge/ARCHITECTURE.md` and `knowledge/HOW_TO_RUN.md` as the source of truth for structure and commands.
- Keep acceptance criteria observable and tied to commands, inspectable artifacts, or concrete playtest steps.
- For gameplay logic, prefer pure helper tests or manager integration tests before UI-only assertions.
- For UI and scene work, include smoke coverage that instantiates the relevant scene when feasible.
- For data-driven features, validate that JSON/resource IDs, types, and references remain consistent.
- If the task is ambiguous, choose the smallest implementation that still delivers the stated player outcome.
