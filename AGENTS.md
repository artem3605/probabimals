# AGENTS.md

## Cursor Cloud specific instructions

### Overview

Probabimals is a Godot 4.6 GDScript dice strategy game — a single project with no backend, database, or external services. See `README.md` and `knowledge/ARCHITECTURE.md` for game design details.

### Running the game

```bash
# Start virtual display (required — no physical GPU in cloud VMs)
Xvfb :99 -screen 0 1280x720x24 -ac +extension GLX +render -noreset &
export DISPLAY=:99

# Run the game
godot --path /workspace
```

ALSA audio warnings are expected and harmless — the VM has no sound card.

### Linting

GDScript linting is available via `gdtoolkit` (installed via pip):

```bash
gdlint scripts/          # lint all scripts
gdformat --check scripts/ # check formatting (use without --check to auto-format)
```

No automated test framework (e.g., GUT) is currently configured in this project.

### Importing / rebuilding assets

```bash
godot --headless --path /workspace --import
```

This re-scans and reimports all assets. Useful after pulling changes that add or modify resources.

### Key caveats

- Godot 4.6 is installed at `/usr/local/bin/godot`. The update script ensures it stays installed.
- The project uses GL Compatibility renderer — works with Mesa software rendering (`llvmpipe`) in the VM.
- No package manager lockfile — dependencies are just the Godot engine binary and `gdtoolkit` (pip).
