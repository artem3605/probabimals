#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GODOT_BIN="${GODOT:-godot}"
GODOT_HOME="${GODOT_HOME_OVERRIDE:-$PROJECT_ROOT/.godot-home}"

cd "$PROJECT_ROOT"

mkdir -p "$GODOT_HOME/.config"
mkdir -p "$GODOT_HOME/.local/share/godot/app_userdata/Probabimals"
mkdir -p "$GODOT_HOME/.local/share/godot/logs"
mkdir -p "$GODOT_HOME/Library/Application Support/Godot/app_userdata/Probabimals"
mkdir -p "$GODOT_HOME/Library/Application Support/Godot/logs"

export HOME="$GODOT_HOME"
export XDG_CONFIG_HOME="$GODOT_HOME/.config"
export XDG_DATA_HOME="$GODOT_HOME/.local/share"

if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
  echo "ERROR: Godot executable '$GODOT_BIN' was not found in PATH." >&2
  echo "Install Godot 4.6 or set GODOT=/path/to/godot before running validation." >&2
  exit 127
fi

echo "Running Godot import/syntax sanity check..."
"$GODOT_BIN" --headless --path "$PROJECT_ROOT" --import

echo "Compiling Python helper scripts..."
python3 -m compileall -q scripts/tools
