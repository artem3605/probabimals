.PHONY: install-dev test lint format-check format typecheck static-check security build export-web export-web-dev validate

GDSCRIPT_PATHS := scripts scenes tests
PYTHON ?= python3
GODOT ?= godot
WEB_DEV_EXPORT ?= /tmp/probabimals-web-dev/probabimals-dev.html

install-dev:
	$(PYTHON) -m pip install -r requirements-dev.txt

test:
	./scripts/test/run_gut.sh

lint:
	gdlint $(GDSCRIPT_PATHS)
	ruff check scripts/tools

format-check:
	gdformat --check $(GDSCRIPT_PATHS)
	ruff format --check scripts/tools

format:
	gdformat $(GDSCRIPT_PATHS)
	ruff format scripts/tools

typecheck:
	pyright

static-check:
	GODOT="$(GODOT)" ./scripts/test/run_static_checks.sh

security:
	$(PYTHON) -m pip_audit -r requirements-dev.txt

build: export-web-dev

export-web:
	mkdir -p build/web
	$(GODOT) --headless --import
	$(GODOT) --headless --export-release "Web" build/web/index.html

export-web-dev:
	mkdir -p "$(dir $(WEB_DEV_EXPORT))"
	$(GODOT) --headless --import
	$(GODOT) --headless --export-release "Web Dev" "$(WEB_DEV_EXPORT)"

validate: static-check lint format-check typecheck security test
