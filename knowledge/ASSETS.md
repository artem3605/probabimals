# Assets — Formats, Tools & Workflows

## Graphic Formats

| Format | Use Case | Notes |
|--------|----------|-------|
| **PNG** | Sprites, UI elements, reel symbols, backgrounds | Lossless, alpha transparency, Godot imports natively. Primary format for everything. |
| **SVG** | Simple icons, scalable UI elements | Godot 4 supports SVG import; scales without quality loss. |
| **WebP** | Alternative to PNG when smaller file size matters | Godot 4 supports both lossless and lossy WebP. |

Avoid JPEG — no alpha channel, compression artifacts.

## Audio Formats

| Format | Use Case | Notes |
|--------|----------|-------|
| **WAV** | Short sound effects (clicks, spins, jingles) | Uncompressed = zero playback latency. Export at 16-bit, 44100 Hz, mono. |
| **OGG Vorbis** | Music, ambient loops, longer audio | Compressed, supports streaming. Quality 6–8, stereo. |
| **MP3** | Acceptable alternative to OGG | Godot 4 supports it, but OGG is generally preferred. |

Rule of thumb: **SFX → WAV, music/ambience → OGG**.

## Font Formats

| Format | Notes |
|--------|-------|
| **TTF / OTF** | Godot 4 supports both natively via `FontFile`. |

WOFF/WOFF2 are **not** supported by Godot.

Sources: Google Fonts (OFL license), itch.io (many game-oriented fonts), dafont.com (check license).

## UI Resources

- **NinePatch (9-patch) PNGs** — for stretchable panels, buttons, frames. Godot's `NinePatchRect` node stretches the center while preserving corners.
- **`.tres` (Godot Theme Resources)** — for defining reusable UI styles (fonts, colors, margins) across the project.

## Data Formats

| Format | Use Case |
|--------|----------|
| **JSON** | Part definitions, symbol tables, scoring rules |
| **`.tres` (Godot Resource)** | Data editable in Godot Inspector |
| **CSV** | Balance tables (edit in Google Sheets → export) |

---

## Tools

### Art & Sprites

| Tool | Cost | Best For |
|------|------|----------|
| **Aseprite** | ~$20 (or build from source) | Pixel art, spritesheet animation, frame-by-frame work. Gold standard for 2D game art. Has a Godot import plugin. |
| **Krita** | Free | Painted / hand-drawn style, large illustrations, concept art. |
| **Figma** | Free tier | UI/UX wireframes and layout mockups before implementation. Export slices as PNG/SVG. |
| **Inkscape** | Free | Vector graphics, icons. Export to SVG or PNG. |
| **LibreSprite** | Free | Open-source Aseprite fork if budget is zero. |
| **TexturePacker** | Paid | Spritesheet / atlas packing (Godot's built-in atlas is usually enough). |

### Audio

| Tool | Cost | Best For |
|------|------|----------|
| **jsfxr** (web) / **sfxr** | Free | Generating retro-style SFX — clicks, beeps, win/loss stingers. Great for prototyping. |
| **BFXR** | Free | Extended sfxr with more parameters. |
| **Audacity** | Free | Editing, trimming, normalizing audio files. |
| **LMMS** | Free | Music composition (DAW). |
| **FL Studio / Ableton** | Paid | Professional music production. |
| **Freesound.org** | Free | Library of CC-licensed sound samples (always check license). |

### Fonts

| Tool | Cost | Best For |
|------|------|----------|
| **Google Fonts** | Free (OFL) | Wide variety of quality typefaces. |
| **itch.io fonts** | Free / Paid | Game-oriented and pixel fonts. |

---

## Workflows

### Sprite Workflow

1. **Sketch** concept on paper or in Krita.
2. **Draw** final sprite in Aseprite (pixel art) or Krita (painted style).
3. **Export** as PNG — consistent canvas size per category (e.g. all reel symbols at 128×128 px).
4. **Place** into `assets/art/<subfolder>/`.
5. **Godot auto-imports** the file. Configure import settings:
   - **Filter**: `Nearest` for pixel art, `Linear` for smooth art.
   - **Repeat**: off (unless tiling).
6. Use `Sprite2D`, `TextureRect`, or `NinePatchRect` in scenes.

### Spritesheet / Animation Workflow

1. Create frames in Aseprite (frame-by-frame timeline).
2. Export as **spritesheet PNG** + JSON metadata (Aseprite built-in).
3. In Godot: use `AnimatedSprite2D` with `SpriteFrames`, or import via Aseprite plugin.
4. Alternative: for reel spin animation, **programmatic animation** via `Tween` is simpler and more flexible than pre-rendered frames.

### UI Workflow

1. **Design** screens in Figma — layout, spacing, hierarchy.
2. **Slice** individual elements (buttons, panels, card frames) and export as PNG with transparency.
3. For stretchable panels, create **NinePatch** PNGs (small image with defined corner regions).
4. In Godot: build UI with `Control` nodes, apply textures, create a `Theme` resource (`.tres`) for consistent styling.

### Audio Workflow

1. **Prototype** SFX with jsfxr — export as WAV.
2. **Edit** in Audacity — trim silence, normalize volume, fade in/out.
3. **Export**: short SFX as WAV (16-bit, 44100 Hz, mono), music/loops as OGG Vorbis.
4. **Place** into `assets/audio/sfx/` or `assets/audio/music/`.
5. In Godot: use `AudioStreamPlayer` / `AudioStreamPlayer2D`, configure bus routing.

### Font Workflow

1. Find a font that fits the game's visual identity (e.g. vintage/mechanical for slot machines).
2. Download `.ttf` or `.otf`.
3. Place into `assets/fonts/`.
4. In Godot: create a `Theme` resource, assign the font to label/button styles.

---

## BASIC4 — Asset Checklist

BASIC4 explicitly excludes visual polish, animations, and sound. The assets below are the **functional minimum** needed to make the prototype playable and readable. Placeholders (colored rectangles, simple shapes) are perfectly acceptable at this stage.

### Reel Symbols

- **5–8 distinct symbols** for the slot machine reels (e.g. cherry, lemon, star, seven, bell, diamond).
- Size: uniform square (suggested 128×128 px).
- Style: can be simple colored shapes or icons — clarity matters more than beauty.
- Location: `assets/art/symbols/`

### Slot Machine

- **Machine frame / background** — a rectangle or border that visually contains the 3 reels.
- **Reel column background** — subtle distinction for each reel column (or a single strip).
- **Payline indicator** — a horizontal line or highlight showing the active row.
- Location: `assets/art/machines/`

### Parts / Components (Assembly Screen)

- **Part cards** — small visual representations of each part the player can attach to the machine (e.g. a card with an icon and a label).
- **Part slot indicators** — visual cue showing where parts can be placed on the machine.
- Minimum: ~4–6 unique part visuals.
- Location: `assets/art/parts/`

### UI Elements

- **Spin button** — prominent, clearly clickable.
- **Score display** — area showing current score / running total.
- **Spins remaining counter** — text or icon showing activations left.
- **Screen background** — a simple solid or gradient fill.
- **Panel / card frame** — a generic container for information (NinePatch recommended).
- **Result overlay** — simple "Final Score: X" display at the end.
- Location: `assets/art/ui/`

### Font

- **1 primary font** — legible, fits the theme. Used for score, labels, buttons.
- Optional: 1 accent/display font for the title or large numbers.
- Location: `assets/fonts/`

### Audio (Optional for BASIC4)

BASIC4 scope says sound is out, but having minimal SFX makes playtesting more satisfying. If time permits:

- **Spin start** — short mechanical whoosh.
- **Reel stop** — click/thud (one per reel, slight delay between them).
- **Win jingle** — short positive stinger for matching symbols.
- **Button click** — generic UI feedback.
- All can be generated in jsfxr in under 10 minutes.
- Location: `assets/audio/sfx/`

### Data

- **Symbol definitions** — JSON or `.tres` listing each symbol, its rarity/weight, and point value.
- **Part definitions** — JSON or `.tres` listing each part, its effect on the machine.
- **Scoring rules** — JSON or `.tres` defining how matches translate to points.
- Location: `resources/`

### Summary Count

| Category | Items | Priority |
|----------|-------|----------|
| Reel symbols | 5–8 PNGs | Must have |
| Machine frame | 1–2 PNGs | Must have |
| Part cards | 4–6 PNGs | Must have |
| UI elements | 5–6 PNGs | Must have |
| Font | 1–2 TTF/OTF | Must have |
| SFX | 4 WAVs | Nice to have |
| Data files | 3 JSON/tres | Must have |
| **Total graphic assets** | **~16–22 images** | |
