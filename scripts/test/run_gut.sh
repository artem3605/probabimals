#!/usr/bin/env bash

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
GODOT_HOME="${GODOT_HOME_OVERRIDE:-$PROJECT_ROOT/.godot-home}"

mkdir -p "$GODOT_HOME/.config"
mkdir -p "$GODOT_HOME/.local/share/godot/app_userdata/Probabimals"
mkdir -p "$GODOT_HOME/.local/share/godot/logs"
mkdir -p "$GODOT_HOME/Library/Application Support/Godot/app_userdata/Probabimals"
mkdir -p "$GODOT_HOME/Library/Application Support/Godot/logs"

export HOME="$GODOT_HOME"
export XDG_CONFIG_HOME="$GODOT_HOME/.config"
export XDG_DATA_HOME="$GODOT_HOME/.local/share"

EXTRA_ARGS=()
if [[ $# -gt 0 ]]; then
  EXTRA_ARGS=("$@")
fi
if [[ -n "${GUT_JUNIT_XML:-}" ]]; then
  mkdir -p "$(dirname "$GUT_JUNIT_XML")"
  EXTRA_ARGS+=("-gjunit_xml_file=${GUT_JUNIT_XML}")
fi

cd "$PROJECT_ROOT"
exec godot --headless --path "$PROJECT_ROOT" -s res://addons/gut/gut_cmdln.gd -gconfig=res://.gutconfig.json "${EXTRA_ARGS[@]}"
