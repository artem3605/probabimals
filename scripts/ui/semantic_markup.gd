extends RefCounted
## Pure formatter: takes raw dice/modifier description text and returns the
## same string with BBCode color tags applied for RichTextLabel rendering.
## No state, no side effects. All public methods are static.

const SemanticColors = preload("res://scripts/ui/semantic_colors.gd")

const _COIN_ICON := SemanticColors.COIN_ICON_BBCODE

const _COMBO_NAMES := {
	"Yahtzee": "yahtzee",
	"Full House": "full_house",
	"Large Straight": "large_straight",
	"Small Straight": "small_straight",
	"Four of a Kind": "four_same",
	"Three of a Kind": "three_same",
	"Four Same": "four_same",
	"Three Same": "three_same",
	"Two Pair": "two_pair",
	"High Card": "high_card",
	"Pair": "pair",
}


static func format_description(text: String) -> String:
	if text.is_empty():
		return text
	# Idempotency guard: if the text already contains BBCode color tags,
	# assume it's already been formatted and return unchanged.
	if "[color=" in text:
		return text

	var out := text
	out = _apply_combo_names(out)
	out = _apply_multiplicative(out)
	out = _apply_additive(out)
	out = _apply_reroll(out)
	out = _apply_face_replacement_digit(out)
	out = _apply_coin_icon(out)
	out = _apply_rarity(out)
	return out


static func combo_color_hex(combo_type: String) -> String:
	# Try the live priority panel first if it's reachable. The panel is owned
	# by combat_screen and may not exist yet on flea market or dice select.
	var tree := Engine.get_main_loop()
	if tree is SceneTree:
		var root := (tree as SceneTree).root
		if root != null:
			var panels := root.find_children("*", "Control", true, false)
			for node in panels:
				if node.has_method("get_combo_color"):
					var c: Color = node.get_combo_color(combo_type)
					return "#%s" % c.to_html(false)
	return SemanticColors.COMBO_FALLBACK_HEX.get(combo_type, SemanticColors.DEFAULT_HEX)


static func _apply_combo_names(text: String) -> String:
	# Iterate combo display names from longest to shortest so "Two Pair"
	# matches before "Pair", "Three Same" before any digit.
	var out := text
	var keys := _COMBO_NAMES.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())
	for display_name in keys:
		var combo_type: String = _COMBO_NAMES[display_name]
		var hex := combo_color_hex(combo_type)
		# Word boundary on each side, allow trailing 's' for plurals
		# ("Yahtzees", "Full Houses").
		var re := RegEx.new()
		re.compile("\\b%s(s?)\\b" % _re_escape(display_name))
		out = re.sub(out, "[color=%s]$0[/color]" % hex, true)
	return out


static func _re_escape(s: String) -> String:
	# Escape regex metacharacters for the combo display names. Only the chars
	# present in our combo names are handled; expand if names ever change.
	var escaped := s
	escaped = escaped.replace("\\", "\\\\")
	# No metachars in our current names, but this keeps the helper safe for
	# future names that might include "+" or ".".
	for ch in ["+", ".", "*", "?", "(", ")", "[", "]", "{", "}", "^", "$", "|"]:
		escaped = escaped.replace(ch, "\\%s" % ch)
	return escaped


static func _apply_multiplicative(text: String) -> String:
	# "x3", "x3.5", "+4 mult", "4 mult" — wrap the whole match.
	var hex := SemanticColors.MULTIPLICATIVE_HEX
	var out := text
	var re_x := RegEx.new()
	re_x.compile("\\bx\\d+(?:\\.\\d+)?\\b")
	out = re_x.sub(out, "[color=%s]$0[/color]" % hex, true)

	var re_mult := RegEx.new()
	re_mult.compile("\\+?\\d+(?:\\.\\d+)?\\s+mult\\b")
	out = re_mult.sub(out, "[color=%s]$0[/color]" % hex, true)
	return out


static func _apply_additive(text: String) -> String:
	# "+4 sum", "4 sum", "+7 sum" — wrap the whole match.
	var hex := SemanticColors.ADDITIVE_HEX
	var re := RegEx.new()
	re.compile("\\+?\\d+(?:\\.\\d+)?\\s+sum\\b")
	return re.sub(text, "[color=%s]$0[/color]" % hex, true)


static func _apply_reroll(text: String) -> String:
	var hex := SemanticColors.REROLL_HEX
	var re := RegEx.new()
	re.compile("\\+?\\d+\\s+reroll(?:s)?\\b")
	return re.sub(text, "[color=%s]$0[/color]" % hex, true)


static func _apply_face_replacement_digit(text: String) -> String:
	# In face-swap phrases, wrap only the replacement digit.
	var hex := SemanticColors.FACE_VALUE_HEX
	var out := text
	var re_named := RegEx.new()
	re_named.compile("\\b(extra)\\s+(\\d)\\b")
	out = re_named.sub(out, "$1 [color=%s]$2[/color]" % hex, true)
	var re_plain := RegEx.new()
	re_plain.compile("\\bwith\\s+a\\s+(\\d)\\b")
	return re_plain.sub(out, "with a [color=%s]$1[/color]" % hex, true)


static func _apply_coin_icon(text: String) -> String:
	# Replace the words "coins" / "coin" with the coin icon BBCode. Word
	# boundary so substrings like "coinage" are not affected.
	var re := RegEx.new()
	re.compile("\\bcoin(s)?\\b")
	return re.sub(text, _COIN_ICON, true)


static func _apply_rarity(text: String) -> String:
	# Rarity now appears as the bare word on its own line at the end of the
	# description (e.g. "...\nCOMMON"). Anchor on (^|\n) so we don't paint a
	# stray "RARE" that ever shows up mid-sentence.
	var re := RegEx.new()
	re.compile("(^|\\n)(COMMON|UNCOMMON|RARE)\\b")
	var matches := re.search_all(text)
	if matches.is_empty():
		return text
	var out := text
	# Walk in reverse so prior offsets stay valid as we splice replacements in.
	for i in range(matches.size() - 1, -1, -1):
		var m: RegExMatch = matches[i]
		var rarity := m.get_string(2)
		var hex := SemanticColors.RARITY_COMMON_HEX
		match rarity:
			"UNCOMMON":
				hex = SemanticColors.RARITY_UNCOMMON_HEX
			"RARE":
				hex = SemanticColors.RARITY_RARE_HEX
		var prefix := m.get_string(1)
		var wrapped := "%s[color=%s]%s[/color]" % [prefix, hex, rarity]
		var start_idx := m.get_start()
		var end_idx := m.get_end()
		out = out.substr(0, start_idx) + wrapped + out.substr(end_idx)
	return out


static func format_face_value(value: int) -> String:
	return "[color=%s]%d[/color]" % [SemanticColors.FACE_VALUE_HEX, value]


static func format_faces_list(face_values: Array) -> String:
	var parts := PackedStringArray()
	for v in face_values:
		parts.append(format_face_value(int(v)))
	return ",".join(parts)


static func format_cost(coins: int) -> String:
	return "%s %d" % [SemanticColors.COIN_ICON_BBCODE, coins]


static func coin_icon(size_px: int = 18) -> String:
	return "[img=%d]res://assets/art/ui/coin.png[/img]" % size_px


static func format_rarity(rarity: String) -> String:
	# Returns BBCode-wrapped uppercased rarity, or empty string if blank.
	var r := rarity.strip_edges().to_upper()
	if r.is_empty():
		return ""
	var hex := SemanticColors.RARITY_COMMON_HEX
	match r:
		"UNCOMMON":
			hex = SemanticColors.RARITY_UNCOMMON_HEX
		"RARE":
			hex = SemanticColors.RARITY_RARE_HEX
	return "[color=%s]%s[/color]" % [hex, r]
