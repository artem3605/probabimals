class_name ComboRevealFx
extends Control
## Procedural pixel-art reveal burst for the combo that lands after a combat roll.

const REVEAL_DURATION := 0.82
const BASE_RING_SIZE := 34.0
const PARTICLE_LIFE := 0.58
const PARTICLE_GRAVITY := 140.0
const DARK := Color("1a1a1a")
const GOLD := Color("ffd700")
const PINK := Color("ff5bbd")

var _active := false
var _elapsed := 0.0
var _combo_type := ""
var _reveal_tier := 0
var _reveal_color := GOLD
var _dice_points: Array[Vector2] = []
var _dice_rects: Array[Rect2] = []
var _particles: Array[Dictionary] = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	set_process(false)


func play(combo: Dictionary, dice_cards: Array, color: Color) -> void:
	_combo_type = str(combo.get("type", ""))
	_reveal_tier = int(combo.get("priority", 0))
	_reveal_color = color
	_elapsed = 0.0
	_active = true
	visible = true
	set_process(true)

	_capture_dice_geometry(combo.get("in_combo", []), dice_cards)
	_spawn_particles()
	queue_redraw()


func get_reveal_tier() -> int:
	return _reveal_tier


func get_active_combo_type() -> String:
	return _combo_type


func _process(delta: float) -> void:
	if not _active:
		return
	_elapsed += delta
	if _elapsed >= REVEAL_DURATION:
		_active = false
		visible = false
		set_process(false)
	queue_redraw()


func _capture_dice_geometry(in_combo: Array, dice_cards: Array) -> void:
	_dice_points.clear()
	_dice_rects.clear()
	for i in range(dice_cards.size()):
		var participates := in_combo.is_empty()
		if i < in_combo.size():
			participates = bool(in_combo[i])
		if not participates:
			continue
		var card = dice_cards[i]
		if not card is Control:
			continue
		var rect := (card as Control).get_global_rect()
		var local_pos: Vector2 = rect.position - global_position
		var local_center: Vector2 = rect.position + rect.size * 0.5 - global_position
		_dice_rects.append(Rect2(local_pos, rect.size))
		_dice_points.append(local_center)

	if _dice_points.is_empty():
		_dice_points.append(size * 0.5)


func _spawn_particles() -> void:
	_particles.clear()
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var count := _particle_count_for_tier(_reveal_tier)
	for i in range(count):
		var origin := _dice_points[rng.randi_range(0, _dice_points.size() - 1)]
		var angle := rng.randf_range(-PI * 0.96, -PI * 0.04)
		var speed := rng.randf_range(90.0, 210.0 + float(_reveal_tier) * 18.0)
		var particle_color := _reveal_color
		if _reveal_tier >= 8 and i % 3 == 0:
			particle_color = PINK
		elif i % 4 == 0:
			particle_color = GOLD
		_particles.append({
			"origin": origin + Vector2(rng.randf_range(-18.0, 18.0), rng.randf_range(-10.0, 10.0)),
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"size": rng.randf_range(4.0, 8.0 + float(_reveal_tier) * 0.5),
			"delay": rng.randf_range(0.0, 0.11),
			"color": particle_color,
		})


func _draw() -> void:
	if not _active:
		return

	var t := clampf(_elapsed / REVEAL_DURATION, 0.0, 1.0)
	var out := 1.0 - _ease_out_cubic(t)
	var center := _combo_center()
	var intensity := _tier_intensity(_reveal_tier)

	if _reveal_tier >= 6:
		var flash_color := PINK if _reveal_tier >= 8 else _reveal_color
		flash_color.a = 0.16 * out
		draw_rect(Rect2(Vector2.ZERO, size), flash_color)

	_draw_stepped_glow(center, intensity, out)
	_draw_dice_rings(t, intensity)
	_draw_combo_connections(out)
	_draw_burst_lines(center, t, intensity)
	_draw_particles()


func _draw_stepped_glow(center: Vector2, intensity: float, out: float) -> void:
	var steps := 4 + mini(_reveal_tier, 8)
	var max_radius := 92.0 + float(_reveal_tier) * 13.0
	for step in range(steps):
		var k := float(step + 1) / float(steps)
		var radius := max_radius * k
		var alpha := (1.0 - k) * 0.18 * intensity * out
		var color := _reveal_color
		color.a = alpha
		var rect := Rect2(center - Vector2(radius, radius * 0.48), Vector2(radius * 2.0, radius * 0.96))
		draw_rect(rect, color, false, 4.0)


func _draw_dice_rings(t: float, intensity: float) -> void:
	var wave := _ease_out_cubic(t)
	for rect in _dice_rects:
		var expand := BASE_RING_SIZE * wave + float(_reveal_tier) * 3.0
		var ring := rect.grow(expand)
		var alpha := (1.0 - wave) * 0.68 * intensity
		var color := _reveal_color
		color.a = alpha
		draw_rect(ring, color, false, 4.0)

		if _reveal_tier >= 6:
			var inner := rect.grow(expand * 0.45)
			var inner_color := GOLD if _reveal_tier >= 8 else _reveal_color.lightened(0.25)
			inner_color.a = alpha * 0.65
			draw_rect(inner, inner_color, false, 3.0)


func _draw_combo_connections(out: float) -> void:
	if _reveal_tier < 6 or _dice_points.size() < 2:
		return
	var color := _reveal_color
	color.a = 0.34 * out
	for i in range(_dice_points.size() - 1):
		draw_line(_dice_points[i], _dice_points[i + 1], color, 4.0)


func _draw_burst_lines(center: Vector2, t: float, intensity: float) -> void:
	if _reveal_tier < 3:
		return
	var line_count := 8 if _reveal_tier < 8 else 14
	var base_radius := 62.0 + float(_reveal_tier) * 7.0
	var wave := _ease_out_cubic(t)
	var color := _reveal_color
	color.a = (1.0 - wave) * 0.72 * intensity
	for i in range(line_count):
		var angle := TAU * (float(i) / float(line_count))
		var dir := Vector2(cos(angle), sin(angle))
		var start := center + dir * (base_radius * 0.34 + wave * 18.0)
		var end := center + dir * (base_radius + wave * 32.0)
		draw_line(start, end, color, 4.0)


func _draw_particles() -> void:
	for particle in _particles:
		var local_t := _elapsed - float(particle["delay"])
		if local_t < 0.0 or local_t > PARTICLE_LIFE:
			continue
		var k := local_t / PARTICLE_LIFE
		var origin: Vector2 = particle["origin"]
		var velocity: Vector2 = particle["velocity"]
		var pos := origin + velocity * local_t + Vector2(0.0, PARTICLE_GRAVITY * local_t * local_t)
		var s := float(particle["size"])
		var color: Color = particle["color"]
		color.a = (1.0 - k) * 0.86
		draw_rect(Rect2(pos - Vector2(s * 0.5, s * 0.5), Vector2(s, s)), DARK)
		draw_rect(Rect2(pos - Vector2(s * 0.5 + 1.0, s * 0.5 + 1.0), Vector2(s - 2.0, s - 2.0)), color)


func _combo_center() -> Vector2:
	var center := Vector2.ZERO
	for point in _dice_points:
		center += point
	return center / float(_dice_points.size())


func _particle_count_for_tier(tier: int) -> int:
	if tier <= 0:
		return 4
	if tier <= 2:
		return 10
	if tier <= 5:
		return 20
	if tier <= 7:
		return 32
	return 52


func _tier_intensity(tier: int) -> float:
	if tier <= 0:
		return 0.35
	if tier <= 2:
		return 0.7
	if tier <= 5:
		return 1.0
	if tier <= 7:
		return 1.28
	return 1.55


func _ease_out_cubic(t: float) -> float:
	return 1.0 - pow(1.0 - clampf(t, 0.0, 1.0), 3.0)
