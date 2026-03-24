#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_FILE="$PROJECT_ROOT/project.godot"
TEMPLATE_FILE="$PROJECT_ROOT/docs/playtest_template.md"

if [[ $# -ne 1 ]]; then
	echo "Usage: ./iteration.sh vMAJOR.MINOR.PATCH" >&2
	exit 1
fi

VERSION="$1"
REPORT_FILE="$PROJECT_ROOT/docs/playtest_${VERSION}.md"

if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
	echo "Version must match vMAJOR.MINOR.PATCH" >&2
	exit 1
fi

if [[ -e "$REPORT_FILE" ]]; then
	echo "Refusing to overwrite existing report: $REPORT_FILE" >&2
	exit 1
fi

if [[ ! -f "$PROJECT_FILE" ]]; then
	echo "Missing project file: $PROJECT_FILE" >&2
	exit 1
fi

if [[ ! -f "$TEMPLATE_FILE" ]]; then
	echo "Missing playtest template: $TEMPLATE_FILE" >&2
	exit 1
fi

if grep -q '^config/version=' "$PROJECT_FILE"; then
	perl -0pi -e 's/^config\/version=".*"$/config\/version="'"$VERSION"'"/m' "$PROJECT_FILE"
else
	tmp_file="$(mktemp)"
	awk -v version="$VERSION" '
		/^\[application\]$/ { print; in_application = 1; next }
		in_application && /^config\/name=/ {
			print
			print "config/version=\"" version "\""
			in_application = 0
			next
		}
		{ print }
	' "$PROJECT_FILE" > "$tmp_file"
	mv "$tmp_file" "$PROJECT_FILE"
fi

sed "s/{VERSION}/${VERSION}/g" "$TEMPLATE_FILE" > "$REPORT_FILE"

echo "Updated project version to ${VERSION}"
echo "Created ${REPORT_FILE#$PROJECT_ROOT/}"
echo
echo "Checklist:"
echo "- Export the latest web build for ${VERSION}"
echo "- Create or update the Google Form and paste its share URL into ${REPORT_FILE#$PROJECT_ROOT/}"
echo "- Collect 2 cold-player responses for ${VERSION}"
echo "- Fill the report summary, findings, and next actions"
