extends "res://scripts/ui/pixel_bg.gd"

const MapNodeButtonScene := preload("res://scenes/map/map_node_button.tscn")
const MapNodeRef := preload("res://scripts/map/map_node.gd")

const MAP_CONTENT_SEPARATION := 32
const MAP_TOP_BAR_SEPARATION := 16
const MAP_PANEL_SIZE := Vector2(980, 520)
const MAP_PANEL_MIN_SIZE := Vector2(560, 300)
const MAP_PANEL_MARGIN := 16
const MAP_NODE_SIZE := Vector2(56, 56)
const MAP_NODE_SHADOW_OFFSET := Vector2(5, 5)
const MAP_LEVEL_PADDING_TOP := 72.0
const MAP_LEVEL_PADDING_BOTTOM := 72.0
const MAP_LEVEL_SPACING := 152.0
const MAP_NODE_SIDE_PADDING := 140.0
const MAP_NODE_SPACING := 176.0
const MAP_COIN_PANEL_SIZE := Vector2(124, 48)
const MAP_COIN_ROW_SEPARATION := 8
const MAP_COIN_LABEL_FONT_SIZE := 16
const MAP_COIN_ICON_SIZE := Vector2(24, 24)
const MAP_START_NODE_ID := -1000
const EDGE_COLOR_DIM := Color(0.1, 0.1, 0.1, 0.45)
const EDGE_COLOR_AVAILABLE := Color("ffd700")
const EDGE_COLOR_COMPLETED := Color("9acd32")

var _coin_label: Label
var _map_container: Control
var _map_panel: PanelContainer
var _map_scroll: ScrollContainer
var _all_buttons: Array = []

var _button_by_id: Dictionary = {}
var _position_by_id: Dictionary = {}


func _ready() -> void:
	super._ready()
	_build_ui()
	_update_coins()
	_render_map()
	_map_container.draw.connect(_draw_edges)
	GameManager.coins_changed.connect(func(_amount: int): _update_coins())
	AudioManager.play_music(&"menu")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_instance_valid(_map_panel):
		_refresh_map_layout()


func _draw() -> void:
	_draw_all_bg()
	_draw_button_shadows(_all_buttons, Vector2(4, 4))


func _build_ui() -> void:
	var layout := _make_screen_layout(MAP_CONTENT_SEPARATION, true)
	var content: VBoxContainer = layout["content"]

	_build_top_bar(content)
	_build_map_panel(content)


func _build_top_bar(parent: VBoxContainer) -> void:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", MAP_TOP_BAR_SEPARATION)
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(bar)

	var left_box := HBoxContainer.new()
	left_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(left_box)

	var menu_btn := _make_menu_button()
	menu_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left_box.add_child(menu_btn)
	_all_buttons.append(menu_btn)

	bar.add_child(_make_title_bar("MAP"))

	var right_wrapper := HBoxContainer.new()
	right_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_wrapper.alignment = BoxContainer.ALIGNMENT_END
	bar.add_child(right_wrapper)

	var coin_panel := _make_panel(GOLD, BORDER_BLACK, MAP_COIN_PANEL_SIZE)
	right_wrapper.add_child(coin_panel)

	var coin_hbox := HBoxContainer.new()
	coin_hbox.add_theme_constant_override("separation", MAP_COIN_ROW_SEPARATION)
	coin_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	coin_panel.add_child(coin_hbox)

	coin_hbox.add_child(_create_coin_icon())

	_coin_label = _make_pixel_label("", MAP_COIN_LABEL_FONT_SIZE)
	coin_hbox.add_child(_coin_label)


func _build_map_panel(parent: VBoxContainer) -> void:
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(center)

	_map_panel = _make_panel(CARD_BG, BORDER_BLACK, MAP_PANEL_SIZE, MAP_PANEL_MARGIN)
	_map_panel.custom_minimum_size = _target_map_panel_size(get_viewport_rect().size)
	center.add_child(_map_panel)

	_map_scroll = ScrollContainer.new()
	_map_scroll.name = "MapScroll"
	_map_scroll.custom_minimum_size = (
		_map_panel.custom_minimum_size - Vector2(MAP_PANEL_MARGIN * 2, MAP_PANEL_MARGIN * 2)
	)
	_map_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_panel.add_child(_map_scroll)

	_map_container = Control.new()
	_map_container.name = "MapContainer"
	_map_container.unique_name_in_owner = true
	_map_container.custom_minimum_size = _map_scroll.custom_minimum_size
	_map_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_container.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_map_scroll.add_child(_map_container)
	_map_container.owner = self


func _create_coin_icon() -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = preload("res://assets/art/ui/coin.png")
	rect.custom_minimum_size = MAP_COIN_ICON_SIZE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return rect


func _target_map_panel_size(viewport_size: Vector2) -> Vector2:
	var max_width := viewport_size.x - SCREEN_MARGIN_LEFT - SCREEN_MARGIN_RIGHT
	var max_height := viewport_size.y - SCREEN_MARGIN_TOP - SCREEN_MARGIN_BOTTOM - MAP_CONTENT_SEPARATION - 96.0
	return Vector2(
		clampf(MAP_PANEL_SIZE.x, MAP_PANEL_MIN_SIZE.x, max_width),
		clampf(MAP_PANEL_SIZE.y, MAP_PANEL_MIN_SIZE.y, max_height)
	)


func _target_map_content_size(depth_count: int, viewport_size: Vector2) -> Vector2:
	var visible_panel_size := _target_map_panel_size(viewport_size)
	var visible_content_size := visible_panel_size - Vector2(MAP_PANEL_MARGIN * 2, MAP_PANEL_MARGIN * 2)
	var tall_path_height: float = (
		MAP_LEVEL_PADDING_TOP + MAP_LEVEL_PADDING_BOTTOM + MAP_NODE_SIZE.y + max(0, depth_count - 1) * MAP_LEVEL_SPACING
	)
	return Vector2(visible_content_size.x, maxf(visible_content_size.y, tall_path_height))


func _update_coins() -> void:
	if _coin_label:
		_coin_label.text = str(GameManager.coins)


func _refresh_map_layout() -> void:
	_map_panel.custom_minimum_size = _target_map_panel_size(get_viewport_rect().size)
	_map_scroll.custom_minimum_size = (
		_map_panel.custom_minimum_size - Vector2(MAP_PANEL_MARGIN * 2, MAP_PANEL_MARGIN * 2)
	)
	_map_container.custom_minimum_size = _map_scroll.custom_minimum_size
	_render_map()


func _render_map() -> void:
	for child in _map_container.get_children():
		child.queue_free()
	_button_by_id.clear()
	_position_by_id.clear()

	var run := GameManager.current_run
	if run == null:
		_map_container.queue_redraw()
		queue_redraw()
		return

	var levels: Dictionary = {}
	for id_key in run.nodes.keys():
		var node: MapNodeRef = run.nodes[id_key]
		if not levels.has(node.depth):
			levels[node.depth] = []
		levels[node.depth].append(node)

	var depths := levels.keys()
	depths.sort()
	var min_depth := int(depths[0])
	var max_depth := int(depths[depths.size() - 1])
	var layout_min_depth := min_depth - 1
	_map_container.custom_minimum_size = _target_map_content_size(
		max_depth - layout_min_depth + 1, get_viewport_rect().size
	)
	var container_width := maxf(_map_container.size.x, _map_container.custom_minimum_size.x)
	var container_height := maxf(_map_container.size.y, _map_container.custom_minimum_size.y)
	var usable_height := maxf(
		1.0, container_height - MAP_LEVEL_PADDING_TOP - MAP_LEVEL_PADDING_BOTTOM - MAP_NODE_SIZE.y
	)

	for depth in depths:
		var level: Array = levels[depth]
		level.sort_custom(func(a: MapNodeRef, b: MapNodeRef) -> bool: return a.id < b.id)
		var count := level.size()
		for index in range(count):
			var node: MapNodeRef = level[index]
			var x := _x_for_node(index, count, container_width)
			var y := _y_for_depth(int(depth), layout_min_depth, max_depth, usable_height)
			var btn: MapNodeButton = MapNodeButtonScene.instantiate()
			_map_container.add_child(btn)
			btn.position = Vector2(x, y)
			btn.custom_minimum_size = MAP_NODE_SIZE
			btn.configure(node.id, node.type, _state_for(node, run))
			btn.node_clicked.connect(_on_node_clicked)
			_button_by_id[node.id] = btn
			_position_by_id[node.id] = btn.position + btn.custom_minimum_size * 0.5

	_add_start_node(layout_min_depth, max_depth, container_width, usable_height)

	_map_container.queue_redraw()
	queue_redraw()
	call_deferred("_scroll_to_relevant_node")


func _x_for_node(index: int, count: int, container_width: float) -> float:
	var center_x := container_width * 0.5 - MAP_NODE_SIZE.x * 0.5
	if count <= 1:
		return center_x
	var total_width := minf(float(count - 1) * MAP_NODE_SPACING, container_width - MAP_NODE_SIDE_PADDING * 2.0)
	var step := total_width / float(count - 1)
	return center_x - total_width * 0.5 + float(index) * step


func _y_for_depth(depth: int, min_depth: int, max_depth: int, usable_height: float) -> float:
	if max_depth <= min_depth:
		return MAP_LEVEL_PADDING_TOP + usable_height
	var progress := float(depth - min_depth) / float(max_depth - min_depth)
	return MAP_LEVEL_PADDING_TOP + (1.0 - progress) * usable_height


func _state_for(node: MapNodeRef, run) -> String:
	if run.has_completed(node.id):
		return "completed"
	if run.available_node_ids().has(node.id):
		return "available"
	return "locked"


func _on_node_clicked(node_id: int) -> void:
	GameManager.enter_map_node(node_id)


func _go_to_main_menu() -> void:
	if GameManager.current_run != null:
		GameManager.abandon_run()
	GameManager.go_to_main_menu()


func _add_start_node(layout_min_depth: int, max_depth: int, container_width: float, usable_height: float) -> void:
	var btn: MapNodeButton = MapNodeButtonScene.instantiate()
	_map_container.add_child(btn)
	var x := _x_for_node(0, 1, container_width)
	var y := _y_for_depth(layout_min_depth, layout_min_depth, max_depth, usable_height)
	btn.position = Vector2(x, y)
	btn.custom_minimum_size = MAP_NODE_SIZE
	btn.configure(MAP_START_NODE_ID, MapNodeRef.NodeType.COMBAT, "completed")
	_button_by_id[MAP_START_NODE_ID] = btn
	_position_by_id[MAP_START_NODE_ID] = btn.position + btn.custom_minimum_size * 0.5


func _draw_edges() -> void:
	var run := GameManager.current_run
	if run == null:
		return

	var available := run.available_node_ids()
	_draw_node_shadows()
	_draw_start_edges(run, available)
	for id_key in run.nodes.keys():
		var node: MapNodeRef = run.nodes[id_key]
		if not _position_by_id.has(node.id):
			continue
		var from_pos: Vector2 = _position_by_id[node.id]
		for next_id in node.next_ids:
			var next_node_id := int(next_id)
			if not _position_by_id.has(next_node_id):
				continue
			var to_pos: Vector2 = _position_by_id[next_node_id]
			var col := _edge_color_for(node, next_node_id, run, available)
			_map_container.draw_line(from_pos + Vector2(2, 2), to_pos + Vector2(2, 2), SHADOW_COLOR, 6.0)
			_map_container.draw_line(from_pos, to_pos, col, 4.0)


func _edge_color_for(node: MapNodeRef, next_node_id: int, run, available: Array[int]) -> Color:
	if node.id == run.current_node_id and available.has(next_node_id):
		return EDGE_COLOR_AVAILABLE
	if run.has_completed(node.id) and run.has_completed(next_node_id):
		return EDGE_COLOR_COMPLETED
	return EDGE_COLOR_DIM


func _draw_start_edges(run, available: Array[int]) -> void:
	if not _position_by_id.has(MAP_START_NODE_ID):
		return
	var start_pos: Vector2 = _position_by_id[MAP_START_NODE_ID]
	for id_key in run.nodes.keys():
		var node: MapNodeRef = run.nodes[id_key]
		if node.depth != 1 or not _position_by_id.has(node.id):
			continue
		var to_pos: Vector2 = _position_by_id[node.id]
		var col := EDGE_COLOR_DIM
		if run.has_completed(node.id):
			col = EDGE_COLOR_COMPLETED
		elif available.has(node.id):
			col = EDGE_COLOR_AVAILABLE
		_map_container.draw_line(start_pos + Vector2(2, 2), to_pos + Vector2(2, 2), SHADOW_COLOR, 6.0)
		_map_container.draw_line(start_pos, to_pos, col, 4.0)


func _draw_node_shadows() -> void:
	for id_key in _button_by_id.keys():
		var btn: Button = _button_by_id[id_key]
		if not is_instance_valid(btn):
			continue
		_map_container.draw_rect(Rect2(btn.position + MAP_NODE_SHADOW_OFFSET, btn.size), SHADOW_COLOR)


func _scroll_to_bottom() -> void:
	if not is_instance_valid(_map_scroll):
		return
	var scrollbar := _map_scroll.get_v_scroll_bar()
	_map_scroll.scroll_vertical = int(scrollbar.max_value)


func _scroll_to_relevant_node() -> void:
	if not is_instance_valid(_map_scroll):
		return
	var run := GameManager.current_run
	if run == null:
		return
	var target_id := _scroll_target_node_id(run)
	if not _position_by_id.has(target_id):
		_scroll_to_bottom()
		return

	var target_position: Vector2 = _position_by_id[target_id]
	var visible_height := _map_scroll.size.y
	if visible_height <= 0.0:
		visible_height = _map_scroll.custom_minimum_size.y
	var scrollbar := _map_scroll.get_v_scroll_bar()
	var target_scroll := target_position.y - visible_height * 0.5
	_map_scroll.scroll_vertical = int(clampf(target_scroll, 0.0, scrollbar.max_value))


func _scroll_target_node_id(run) -> int:
	if run.current_node_id == -1:
		return MAP_START_NODE_ID
	var available: Array[int] = run.available_node_ids()
	if not available.is_empty():
		available.sort()
		return available[0]
	return int(run.current_node_id)
