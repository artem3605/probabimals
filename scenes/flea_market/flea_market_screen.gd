extends Control

var bg_texture: Texture2D
var shop_grid: GridContainer
var bag_container: VBoxContainer
var info_panel: PanelContainer
var info_label: RichTextLabel
var coin_label: Label
var selected_item: Dictionary = {}
var selected_die_index: int = -1
var selected_face_index: int = -1
var buy_button: Button
var swap_section: VBoxContainer
var face_buttons_container: HBoxContainer

func _ready() -> void:
	theme = ThemeSetup.game_theme
	bg_texture = load("res://assets/art/ui/felt_background.png")
	_build_ui()
	_populate_shop()
	_update_bag_display()
	_update_coins()
	GameManager.coins_changed.connect(_on_coins_changed)

func _build_ui() -> void:
	var bg := TextureRect.new()
	bg.texture = bg_texture
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 12)
	margin.add_child(main_vbox)

	# Top bar
	_build_top_bar(main_vbox)

	# Content split
	var content := HSplitContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.split_offset = 700
	main_vbox.add_child(content)

	# Left panel: shop
	var shop_panel := PanelContainer.new()
	shop_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_panel.size_flags_stretch_ratio = 1.6
	shop_panel.add_theme_stylebox_override("panel", ThemeSetup.make_panel_style())
	content.add_child(shop_panel)

	var shop_vbox := VBoxContainer.new()
	shop_vbox.add_theme_constant_override("separation", 8)
	shop_panel.add_child(shop_vbox)

	var shop_title := Label.new()
	shop_title.text = "SHOP"
	shop_title.add_theme_font_size_override("font_size", 24)
	shop_title.add_theme_font_override("font", ThemeSetup.font_bold)
	shop_title.add_theme_color_override("font_color", ThemeSetup.COLOR_GOLD)
	shop_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_vbox.add_child(shop_title)

	var shop_scroll := ScrollContainer.new()
	shop_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shop_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	shop_vbox.add_child(shop_scroll)

	shop_grid = GridContainer.new()
	shop_grid.columns = 3
	shop_grid.add_theme_constant_override("h_separation", 10)
	shop_grid.add_theme_constant_override("v_separation", 10)
	shop_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_scroll.add_child(shop_grid)

	# Right panel: dice bag
	var bag_panel := PanelContainer.new()
	bag_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bag_panel.size_flags_stretch_ratio = 1.0
	bag_panel.add_theme_stylebox_override("panel", ThemeSetup.make_panel_style())
	content.add_child(bag_panel)

	var bag_vbox := VBoxContainer.new()
	bag_vbox.add_theme_constant_override("separation", 8)
	bag_panel.add_child(bag_vbox)

	var bag_title := Label.new()
	bag_title.text = "DICE BAG"
	bag_title.add_theme_font_size_override("font_size", 24)
	bag_title.add_theme_font_override("font", ThemeSetup.font_bold)
	bag_title.add_theme_color_override("font_color", ThemeSetup.COLOR_GOLD)
	bag_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bag_vbox.add_child(bag_title)

	var bag_scroll := ScrollContainer.new()
	bag_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bag_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bag_vbox.add_child(bag_scroll)

	bag_container = VBoxContainer.new()
	bag_container.add_theme_constant_override("separation", 8)
	bag_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bag_scroll.add_child(bag_container)

	# Bottom info panel
	_build_info_panel(main_vbox)

	# Fade in
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.4)

func _build_top_bar(parent: VBoxContainer) -> void:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 16)
	parent.add_child(bar)

	var title := Label.new()
	title.text = "FLEA MARKET"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_font_override("font", ThemeSetup.font_bold)
	title.add_theme_color_override("font_color", ThemeSetup.COLOR_GOLD)
	bar.add_child(title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)

	coin_label = Label.new()
	coin_label.add_theme_font_size_override("font_size", 26)
	coin_label.add_theme_font_override("font", ThemeSetup.font_bold)
	coin_label.add_theme_color_override("font_color", ThemeSetup.COLOR_GOLD)
	bar.add_child(coin_label)

	var fight_btn := Button.new()
	fight_btn.text = "FIGHT!"
	fight_btn.custom_minimum_size = Vector2(140, 50)
	fight_btn.add_theme_font_size_override("font_size", 26)
	fight_btn.add_theme_font_override("font", ThemeSetup.font_bold)
	var fight_style := ThemeSetup.make_accent_button_style(Color(0.75, 0.2, 0.15, 0.9))
	fight_btn.add_theme_stylebox_override("normal", fight_style)
	var fight_hover := fight_style.duplicate()
	fight_hover.bg_color = Color(0.85, 0.25, 0.18, 0.95)
	fight_btn.add_theme_stylebox_override("hover", fight_hover)
	fight_btn.add_theme_color_override("font_color", ThemeSetup.COLOR_GOLD)
	fight_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	fight_btn.pressed.connect(_on_fight_pressed)
	bar.add_child(fight_btn)

func _build_info_panel(parent: VBoxContainer) -> void:
	info_panel = PanelContainer.new()
	info_panel.custom_minimum_size = Vector2(0, 130)
	info_panel.add_theme_stylebox_override("panel", ThemeSetup.make_panel_style(
		Color(0.06, 0.06, 0.1, 0.92), ThemeSetup.COLOR_BORDER, 8
	))
	parent.add_child(info_panel)

	var info_hbox := HBoxContainer.new()
	info_hbox.add_theme_constant_override("separation", 16)
	info_panel.add_child(info_hbox)

	info_label = RichTextLabel.new()
	info_label.bbcode_enabled = true
	info_label.fit_content = true
	info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_label.add_theme_font_override("normal_font", ThemeSetup.font_regular)
	info_label.add_theme_font_override("bold_font", ThemeSetup.font_bold)
	info_label.add_theme_font_size_override("normal_font_size", 18)
	info_label.add_theme_font_size_override("bold_font_size", 20)
	info_label.text = "Select an item from the shop or a die from your bag."
	info_hbox.add_child(info_label)

	var btn_vbox := VBoxContainer.new()
	btn_vbox.add_theme_constant_override("separation", 8)
	btn_vbox.custom_minimum_size = Vector2(180, 0)
	info_hbox.add_child(btn_vbox)

	buy_button = Button.new()
	buy_button.text = "BUY"
	buy_button.custom_minimum_size = Vector2(160, 45)
	buy_button.add_theme_font_size_override("font_size", 22)
	buy_button.add_theme_font_override("font", ThemeSetup.font_bold)
	var buy_style := ThemeSetup.make_accent_button_style(Color(0.15, 0.5, 0.2, 0.9))
	buy_button.add_theme_stylebox_override("normal", buy_style)
	var buy_hover := buy_style.duplicate()
	buy_hover.bg_color = Color(0.18, 0.6, 0.25, 0.95)
	buy_button.add_theme_stylebox_override("hover", buy_hover)
	buy_button.add_theme_color_override("font_color", ThemeSetup.COLOR_GOLD)
	buy_button.add_theme_color_override("font_hover_color", Color.WHITE)
	buy_button.pressed.connect(_on_buy_pressed)
	buy_button.visible = false
	btn_vbox.add_child(buy_button)

	swap_section = VBoxContainer.new()
	swap_section.visible = false
	swap_section.add_theme_constant_override("separation", 4)
	btn_vbox.add_child(swap_section)

	var swap_label := Label.new()
	swap_label.text = "Select face to replace:"
	swap_label.add_theme_font_size_override("font_size", 14)
	swap_section.add_child(swap_label)

	face_buttons_container = HBoxContainer.new()
	face_buttons_container.add_theme_constant_override("separation", 4)
	swap_section.add_child(face_buttons_container)

func _populate_shop() -> void:
	for child in shop_grid.get_children():
		child.queue_free()

	var catalogue := DataManager.get_shop_catalogue()
	for item in catalogue:
		var card := _create_shop_card(item)
		shop_grid.add_child(card)

func _create_shop_card(item: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(195, 140)
	var card_style := ThemeSetup.make_panel_style(
		Color(0.08, 0.08, 0.12, 0.9), Color(0.5, 0.4, 0.1, 0.5), 8
	)
	card.add_theme_stylebox_override("panel", card_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	# Category badge
	var cat_label := Label.new()
	var category: String = item.get("category", "")
	cat_label.text = category.to_upper()
	cat_label.add_theme_font_size_override("font_size", 12)
	match category:
		"die":
			cat_label.add_theme_color_override("font_color", ThemeSetup.COLOR_CYAN)
		"face":
			cat_label.add_theme_color_override("font_color", ThemeSetup.COLOR_GREEN)
		"modifier":
			cat_label.add_theme_color_override("font_color", ThemeSetup.COLOR_MAGENTA)
	vbox.add_child(cat_label)

	# Name
	var name_label := Label.new()
	name_label.text = item.get("name", "Unknown")
	name_label.add_theme_font_size_override("font_size", 17)
	name_label.add_theme_font_override("font", ThemeSetup.font_bold)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_label)

	# Description (truncated)
	var desc := Label.new()
	var desc_text: String = item.get("description", "")
	if desc_text.length() > 60:
		desc_text = desc_text.substr(0, 57) + "..."
	desc.text = desc_text
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", ThemeSetup.COLOR_TEXT_MUTED)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(0, 36)
	vbox.add_child(desc)

	# Cost
	var cost_label := Label.new()
	cost_label.text = str(item.get("cost", 0)) + " coins"
	cost_label.add_theme_font_size_override("font_size", 16)
	cost_label.add_theme_font_override("font", ThemeSetup.font_bold)
	cost_label.add_theme_color_override("font_color", ThemeSetup.COLOR_GOLD)
	vbox.add_child(cost_label)

	# Click handler
	var click_btn := Button.new()
	click_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	click_btn.flat = true
	click_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	click_btn.pressed.connect(_on_shop_item_selected.bind(item, card))
	card.add_child(click_btn)

	return card

func _update_bag_display() -> void:
	for child in bag_container.get_children():
		child.queue_free()

	var dice := GameManager.dice_bag.get_all()
	for i in range(dice.size()):
		var die_row := _create_die_row(dice[i], i)
		bag_container.add_child(die_row)

func _create_die_row(die: Die, index: int) -> PanelContainer:
	var panel := PanelContainer.new()
	var is_selected := (index == selected_die_index)
	var border_color := ThemeSetup.COLOR_GOLD if is_selected else Color(0.3, 0.3, 0.35, 0.5)
	var bg_color := Color(0.12, 0.11, 0.07, 0.9) if is_selected else Color(0.07, 0.07, 0.1, 0.8)
	panel.add_theme_stylebox_override("panel", ThemeSetup.make_panel_style(bg_color, border_color, 8))

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	panel.add_child(hbox)

	var die_label := Label.new()
	die_label.text = "Die " + str(index + 1) + ":"
	die_label.add_theme_font_size_override("font_size", 16)
	die_label.add_theme_font_override("font", ThemeSetup.font_bold)
	die_label.custom_minimum_size = Vector2(60, 0)
	hbox.add_child(die_label)

	for f in range(die.faces.size()):
		var face_btn := Button.new()
		face_btn.text = str(die.faces[f])
		face_btn.custom_minimum_size = Vector2(38, 38)
		face_btn.add_theme_font_size_override("font_size", 18)
		face_btn.add_theme_font_override("font", ThemeSetup.font_bold)

		var face_style := StyleBoxFlat.new()
		face_style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
		face_style.border_color = Color(0.4, 0.35, 0.2, 0.6)
		face_style.set_border_width_all(1)
		face_style.set_corner_radius_all(6)
		face_style.set_content_margin_all(4)
		face_btn.add_theme_stylebox_override("normal", face_style)
		var hover_style := face_style.duplicate()
		hover_style.border_color = ThemeSetup.COLOR_GOLD
		face_btn.add_theme_stylebox_override("hover", hover_style)
		face_btn.add_theme_color_override("font_color", Color.WHITE)
		hbox.add_child(face_btn)

	# Click handler for the whole row
	var click_btn := Button.new()
	click_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	click_btn.flat = true
	click_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	click_btn.pressed.connect(_on_die_selected.bind(index))
	panel.add_child(click_btn)

	return panel

func _update_coins() -> void:
	coin_label.text = "Coins: " + str(GameManager.coins)

func _on_coins_changed(_amount: int) -> void:
	_update_coins()

func _on_shop_item_selected(item: Dictionary, _card: PanelContainer) -> void:
	selected_item = item
	var category: String = item.get("category", "")
	var desc: String = item.get("description", "")

	var bbcode := "[b]%s[/b]\n%s\n[color=#e8c832]Cost: %d coins[/color]" % [
		item.get("name", ""), desc, item.get("cost", 0)
	]
	info_label.text = bbcode

	if category == "face":
		buy_button.visible = false
		if selected_die_index >= 0:
			_show_face_swap_ui(item)
		else:
			swap_section.visible = false
			info_label.text += "\n[color=#aaa]Select a die from your bag first.[/color]"
			buy_button.visible = true
			buy_button.text = "SELECT DIE FIRST"
			buy_button.disabled = true
	else:
		swap_section.visible = false
		buy_button.visible = true
		buy_button.text = "BUY"
		buy_button.disabled = GameManager.coins < item.get("cost", 0)

func _show_face_swap_ui(item: Dictionary) -> void:
	swap_section.visible = true
	buy_button.visible = false

	for child in face_buttons_container.get_children():
		child.queue_free()

	var die := GameManager.dice_bag.get_die(selected_die_index)
	if die == null:
		return

	var face_value: int = item.get("params", {}).get("value", 1)
	for f in range(die.faces.size()):
		var btn := Button.new()
		btn.text = str(die.faces[f])
		btn.custom_minimum_size = Vector2(36, 36)
		btn.add_theme_font_size_override("font_size", 16)
		btn.tooltip_text = "Replace %d with %d" % [die.faces[f], face_value]
		btn.pressed.connect(_on_face_swap.bind(f, face_value, item))
		face_buttons_container.add_child(btn)

func _on_face_swap(face_index: int, new_value: int, item: Dictionary) -> void:
	if GameManager.coins < item.get("cost", 0):
		return
	GameManager.coins -= item.get("cost", 0)
	GameManager.coins_changed.emit(GameManager.coins)
	GameManager.swap_face(selected_die_index, face_index, new_value)
	_update_bag_display()
	swap_section.visible = false
	info_label.text = "Face swapped successfully!"

func _on_die_selected(index: int) -> void:
	selected_die_index = index
	_update_bag_display()
	var die := GameManager.dice_bag.get_die(index)
	if die:
		var faces_str := ""
		for f in die.faces:
			faces_str += str(f) + " "
		info_label.text = "[b]Die %d[/b]\nFaces: %s" % [index + 1, faces_str.strip_edges()]

	if not selected_item.is_empty() and selected_item.get("category", "") == "face":
		_show_face_swap_ui(selected_item)

func _on_buy_pressed() -> void:
	if selected_item.is_empty():
		return
	var success := GameManager.buy_item(selected_item)
	if success:
		info_label.text = "[color=#33dd55]Purchased: %s[/color]" % selected_item.get("name", "")
		_update_bag_display()
		buy_button.disabled = true
	else:
		info_label.text = "[color=#dd3333]Not enough coins![/color]"

func _on_fight_pressed() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(GameManager.go_to_combat)
