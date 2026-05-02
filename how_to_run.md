# How to Run Probabimals

## Install Godot on macOS

If `godot` is not available in `PATH`, install it with Homebrew:

```bash
brew install --cask godot
godot --version
```

## Rebuild the Web export

From the repository root:

```bash
cd /path/to/probabimals
godot --headless --import
godot --headless --export-release "Web" build/web/index.html
```

This regenerates:

- `build/web/index.html`
- `build/web/index.pck`
- `build/web/index.wasm`

Note:

- `Web` is the production-style export and keeps PWA/service worker enabled.
- For local verification, prefer `Web Dev` below to avoid stale browser cache.

## Rebuild a clean local dev export

Use the cache-safe preset for local testing:

```bash
cd /path/to/probabimals
godot --headless --import
mkdir -p /tmp/probabimals-web-dev
godot --headless --export-release "Web Dev" /tmp/probabimals-web-dev/probabimals-dev.html
```

This export:

- disables PWA/service worker
- uses a separate output filename (`probabimals-dev.*`)
- avoids exporting into the project `build/` directory itself

This matters because exporting into `build/` from a preset with `export_filter="all_resources"` can make later exports pull previous build artifacts back into the `.pck`.

## Run the Web build locally

Serve the exported files over HTTP:

```bash
python3 -m http.server 8000 --directory build/web
```

Then open `http://127.0.0.1:8000/` in a browser.

If port `8000` is busy, use another port, for example:

```bash
python3 -m http.server 8001 --directory build/web
```

For the clean local dev export:

```bash
python3 -m http.server 8011 --directory /tmp/probabimals-web-dev
```

Then open `http://127.0.0.1:8011/probabimals-dev.html`.

## Run from the Godot editor

```bash
godot --path /path/to/probabimals
```

Default main scene:

- `res://scenes/main_menu/main_menu.tscn`

## Run the automated tests

The repository ships with GUT vendored in `addons/gut` and a single canonical runner:

```bash
cd /path/to/probabimals
make test
```

Optional JUnit XML export for CI or local inspection:

```bash
cd /path/to/probabimals
GUT_JUNIT_XML=build/test-results/gut.xml make test
```

Test layout:

- `tests/unit` for pure logic
- `tests/integration` for manager/state flows
- `tests/smoke` for headless boot and structural coverage

## Run validation checks

Install the Python development tools once:

```bash
cd /path/to/probabimals
make install-dev
```

Then run the full validation loop:

```bash
make validate
```

Focused checks:

```bash
make static-check   # Godot import/syntax sanity + Python bytecode compilation
make lint           # gdlint + ruff
make format-check   # gdformat --check + ruff format --check
make typecheck      # pyright
make security       # pip-audit against pinned dev requirements
```

If the Godot executable is not named `godot`, pass it explicitly:

```bash
GODOT=/path/to/Godot make static-check
```

Optional pre-commit hooks are configured in `.pre-commit-config.yaml`:

```bash
pre-commit install
```

## Notes

- `build/web/index.html` loads Poki SDK from `https://game-cdn.poki.com/scripts/v2/poki-sdk.js`, so the browser needs network access to that domain.
- In this workspace, the Web export was rebuilt successfully with `Godot 4.6.1` using the commands above.
- In this environment, headless Godot prints warnings about macOS CA certificates and saving editor settings, but the export still completes successfully.
