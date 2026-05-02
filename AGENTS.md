# Probabimals Agent Guide

## Project Context

Probabimals is a Godot 4.6 dice strategy game written in GDScript. Runtime code lives in `scripts/`, scenes in `scenes/`, data in `resources/data/`, tests in `tests/`, and vendored plugins in `addons/`.

Read these first when planning work:

1. `.codex/project-context.md`
2. `knowledge/ARCHITECTURE.md`
3. `knowledge/HOW_TO_RUN.md`
4. `README.md`
5. The source, scene, data, and test files for the active change

## Setup

Install Godot 4.6 and make sure `godot` is in `PATH`. If the executable has another name or path, run validation with `GODOT=/path/to/godot`.

Install Python development tools from the repo root:

```bash
make install-dev
```

## Validation Commands

Use the strongest relevant check for the files touched:

- `make test` runs the vendored GUT suite through `scripts/test/run_gut.sh`.
- `make static-check` runs Godot import/syntax sanity and compiles Python helper scripts.
- `make lint` runs `gdlint` on project GDScript and `ruff check` on Python tools.
- `make format-check` checks GDScript and Python formatting.
- `make typecheck` runs Pyright on Python helper scripts.
- `make security` audits pinned Python dev dependencies.
- `make validate` runs the full local validation loop.
- `make build` creates a cache-safe Web Dev export.

For CI-style test output:

```bash
GUT_JUNIT_XML=build/test-results/gut.xml make test
```

## Working Rules

- Do not edit vendored plugin code under `addons/` unless the task explicitly targets plugin integration.
- Do not commit generated export output under `build/`.
- Preserve gameplay behavior unless the request explicitly changes it.
- Prefer data-driven game parameters in `resources/data/*.json` over hardcoded values.
- Keep scene communication signal-driven and route phase changes through `GameManager`.
- Update docs when setup, validation, architecture, or gameplay behavior changes.
