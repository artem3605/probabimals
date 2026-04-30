# Codex-Native Harness v1

This harness is a repo-local workflow layer for Probabimals. It is not part of the game runtime. The current Codex thread acts as the controller and may coordinate `planner`, `generator`, and `evaluator` roles against committed prompts and per-run artifacts.

## Goals

- Keep long-running game work coherent by separating planning, implementation, and QA.
- Force work into small vertical slices with explicit acceptance criteria.
- Preserve independent QA by keeping `evaluator` read/check only.
- Make every run reproducible from tracked prompts, templates, and project context.

## Directory Layout

Tracked:

```text
.codex/
  project-context.md
  harness/
    README.md
    prompts/
      controller.md
      planner.md
      generator.md
      evaluator.md
    templates/
      request.md
      spec.md
      backlog.json
      state.json
      contract.md
      build-report.md
      qa-report.md
```

Ignored local artifacts:

```text
.codex/runs/<YYYY-MM-DD>-<slug>/
  request.md
  spec.md
  backlog.json
  state.json
  sprints/
    01/
      contract.md
      build-report.md
      qa-report.md
```

## Bootstrap

1. Create a new run directory at `.codex/runs/<YYYY-MM-DD>-<slug>/`.
2. Copy these templates into the run directory:
   - `request.md`
   - `spec.md`
   - `backlog.json`
   - `state.json`
3. Create `.codex/runs/<run_id>/sprints/01/` and copy:
   - `contract.md`
   - `build-report.md`
   - `qa-report.md`
4. Fill `request.md` with the user objective, constraints, and success criteria.
5. Initialize `state.json` with the new `run_id`, `objective`, `phase="planning"`, `status="running"`, `sprint_index=1`, and `attempt=0`.
6. Run the controller protocol in `.codex/harness/prompts/controller.md`.

## Controller Loop

1. Read `.codex/project-context.md`, `.codex/harness/README.md`, and the current run artifacts.
2. Use a fresh `planner` role for the planning phase.
3. Planner writes `spec.md` and `backlog.json`.
4. Controller picks one backlog item with `status="todo"` and marks it active in `state.json`.
5. Use a fresh `generator` role in `contract` mode for the active backlog item.
6. Generator writes or updates `sprints/<nn>/contract.md`.
7. Use a fresh `evaluator` role in `contract_review` mode.
8. Evaluator reads the contract and writes `sprints/<nn>/qa-report.md` with verdict:
   - `PASS` if the contract is specific and verifiable.
   - `FAIL` if the contract is incomplete, too broad, or unverifiable.
   - `BLOCKED` only if required prerequisites are unavailable.
9. If contract review is not `PASS`, controller increments `attempt`, routes the latest `qa-report.md` back to a fresh `generator`, and repeats steps 5-8.
10. Once contract review passes, use a fresh `generator` role in `build` mode.
11. Generator implements only the approved slice and writes `sprints/<nn>/build-report.md`.
12. Use a fresh `evaluator` role in `build_qa` mode.
13. Evaluator validates the implementation, runs only approved checks, and writes `sprints/<nn>/qa-report.md`.
14. If build QA is `PASS`, controller marks the backlog item `done`, advances to the next backlog item, resets `attempt` to `0`, and creates the next sprint directory if needed.
15. If build QA is `FAIL`, controller increments `attempt` and hands the latest `contract.md` plus `qa-report.md` to a fresh `generator` for another build attempt.
16. If build QA is `BLOCKED`, controller stops the run and leaves a blocker note in `state.json`.

## Agent Ownership Rules

- Controller owns:
  - `state.json`
  - backlog item selection and status changes in `backlog.json`
  - role sequencing and retry decisions
- Planner owns:
  - `spec.md`
  - initial population of `backlog.json`
- Generator owns:
  - `sprints/<nn>/contract.md`
  - application code changes for the active slice
  - `sprints/<nn>/build-report.md`
- Evaluator owns:
  - `sprints/<nn>/qa-report.md`

Hard rules:

- Only one backlog item may be active at a time.
- Only one implementation/evaluation role may be in progress at a time.
- Every phase uses a fresh role context; do not reuse a prior planner, generator, or evaluator context.
- `evaluator` must never edit tracked application files.
- `generator` must never write `qa-report.md`.
- `planner` must not edit application code.

## Retry Policy

- Maximum `3` attempts per backlog item, counting both contract and build retries.
- Any unmet core acceptance criterion is an automatic `FAIL`.
- `BLOCKED` is reserved for missing prerequisites, unavailable services/tools, or checks that cannot be run in the current environment.
- After `3` failed attempts on the same backlog item, stop the run and leave the item in `blocked` status with a clear failure summary in `state.json`.

## Verification Policy

Evaluator may run only checks declared in the current `contract.md` and allowed by the current environment.

Default approved checks:

- Godot import/syntax sanity after scenes, resources, or GDScript changes: `godot --headless --import`
- Primary automated regression check after game/runtime/test changes: `./scripts/test/run_gut.sh`
- Web Dev export only when the slice touches export or browser behavior: `godot --headless --export-release "Web Dev" /tmp/probabimals-web-dev/probabimals-dev.html`
- Manual editor/native/browser checks only when explicitly declared in the contract

If the contract contains acceptance criteria that cannot be verified with available commands and environment, evaluator must mark them unverified and refuse `PASS`.

## Stop Conditions

Stop the run when any of the following is true:

- All backlog items are `done`
- An item reaches the max retry limit
- Evaluator returns `BLOCKED`
- The user changes the objective enough to invalidate the current spec

## Extension Note

v1 is terminal-first. Browser or editor playtesting can be added to a contract when a slice needs visual or interaction proof, but headless GUT/import checks remain the default verification path.
