# Tech Stack

## Engine

**Godot 4.x** with **GDScript**

### Why Godot

- Free and open-source — no licensing fees or revenue share.
- Best-in-class 2D engine — ideal for a UI-heavy game with slot machines, drag-and-drop assembly, and card-like part displays.
- Built-in visual editor — scenes, animations, particles, and UI layouts are created visually, not purely in code.
- Signal system — native event-driven architecture, perfect for "reel stopped → calculate result → play animation" flows.
- One-click export — builds for Windows, macOS, Linux (and optionally web/mobile) with minimal configuration.
- Lightweight — ~40 MB engine, fast iteration cycle.

### Why GDScript

- Python-like syntax — low barrier to entry.
- First-class Godot integration — autocomplete, debugger, profiler all work out of the box.
- Sufficient for the project's complexity — no need for C# or C++ performance.

## Target Platform

- **Primary:** Desktop (Windows, macOS, Linux)
- **Stretch:** Web export (Godot supports HTML5)

## Project Structure (Godot conventions)

```
project.godot          # Godot project file
scenes/                # .tscn scene files
scripts/               # .gd script files
assets/
  art/                 # sprites, textures
  audio/               # sound effects, music
  fonts/               # typefaces
resources/             # .tres resource files (themes, data)
```

## Version Control

- Git with `.gitignore` tailored for Godot (ignore `.godot/` cache directory).
- Knowledge docs remain in `knowledge/` at repo root.
