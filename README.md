# Probabimals

**[Play in Browser](https://artem3605.github.io/probabimals/)**

A round-based dice strategy game inspired by Yahtzee and Balatro. Collect and customize dice at the shop, then roll combos in combat to beat escalating score targets. Built with Godot 4.x.

## Setup

Install Godot 4.6 and make sure `godot` is available in `PATH`. For validation tooling:

```bash
make install-dev
```

## Validation

Run the full local validation loop from the repository root:

```bash
make validate
```

Useful focused commands:

- `make test` runs the GUT test suite.
- `make static-check` runs Godot import/syntax sanity and Python bytecode compilation.
- `make lint` runs GDScript and Python lint checks.
- `make format-check` verifies formatting.
- `make typecheck` runs Python type checks.
- `make security` audits Python dev dependencies.
- `make build` creates a local cache-safe Web Dev export.

See `how_to_run.md` for export, local web, and editor workflows.