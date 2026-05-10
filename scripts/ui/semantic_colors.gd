extends RefCounted
## Single source of truth for the semantic color palette used in dice and
## modifier descriptions, dice face digits, rarity lines, and the coin icon.
## Hex strings are kept alongside Color values so RichTextLabel BBCode tags can
## be assembled without re-converting.

const FACE_VALUE := Color("#7fdfff")
const FACE_VALUE_HEX := "#7fdfff"

const ADDITIVE := Color("#7ed957")
const ADDITIVE_HEX := "#7ed957"

const MULTIPLICATIVE := Color("#ff5a4a")
const MULTIPLICATIVE_HEX := "#ff5a4a"

const REROLL := Color("#c58fff")
const REROLL_HEX := "#c58fff"

const RARITY_COMMON := Color("#aaaaaa")
const RARITY_COMMON_HEX := "#aaaaaa"

const RARITY_UNCOMMON := Color("#5dd6c2")
const RARITY_UNCOMMON_HEX := "#5dd6c2"

const RARITY_RARE := Color("#ff5dbb")
const RARITY_RARE_HEX := "#ff5dbb"

const DEFAULT := Color("#ffffff")
const DEFAULT_HEX := "#ffffff"

# Combo color fallbacks. Used only if combat_probability_panel hasn't built rows
# yet (e.g. shop shown before any combat). When the panel exists,
# SemanticMarkup looks up the live column color instead.
# Mapping mirrors the priority panel column order: high-priority combos
# (Yahtzee, Four Same, Large Straight) live in the PINK column; mid-tier
# (Full House, Small Straight, Three Same) in BLUE; low-tier (Two Pair, Pair,
# High Card) in ORANGE.
const COMBO_FALLBACK_HEX := {
	"high_card": "#ffb56b",  # ORANGE
	"pair": "#ffb56b",
	"two_pair": "#ffb56b",
	"three_same": "#7fb6ff",  # BLUE
	"small_straight": "#7fb6ff",
	"full_house": "#7fb6ff",
	"large_straight": "#ff7eb6",  # PINK
	"four_same": "#ff7eb6",
	"yahtzee": "#ff7eb6",
}

const COIN_ICON_BBCODE := "[img=18]res://assets/art/ui/coin.png[/img]"
