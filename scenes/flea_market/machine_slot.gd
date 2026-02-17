extends PanelContainer

signal clicked()

const REEL_ICON_PATH := "res://assets/images/parts/standard_reel.png"
const PART_ICON_SIZE := 24

var machine: Machine = null

@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel
@onready var part_icons: HBoxContainer = $MarginContainer/VBoxContainer/PartIcons
@onready var parts_label: Label = $MarginContainer/VBoxContainer/PartsLabel
@onready var hint_label: Label = $MarginContainer/VBoxContainer/HintLabel


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	update_display()


func has_machine() -> bool:
	return machine != null


func get_machine() -> Machine:
	return machine


func setup_machine(m: Machine) -> void:
	machine = m
	update_display()


func update_display() -> void:
	if not is_inside_tree():
		return

	_refresh_icons()

	if machine == null:
		status_label.text = "[ Empty Slot ]"
		status_label.remove_theme_color_override("font_color")
		parts_label.text = ""
		hint_label.text = "Click to place a Frame"
		hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	else:
		var status := "READY!" if machine.is_complete() else "Incomplete"
		if machine.is_complete():
			status_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		else:
			status_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
		status_label.text = "%s [%s]" % [machine.id, status]
		parts_label.text = "Reels: %d/3 | Levers: %d | Mods: %d" % [
			machine.reels.size(),
			machine.levers.size(),
			machine.modifiers.size(),
		]
		if not machine.is_complete():
			var missing: Array[String] = []
			if machine.reels.size() < 3:
				missing.append("%d more Reel(s)" % (3 - machine.reels.size()))
			if machine.levers.size() < 1:
				missing.append("a Lever")
			hint_label.text = "Needs: " + ", ".join(missing)
			hint_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.4))
		else:
			hint_label.text = "Spins: %d | Click to add modifiers" % machine.get_total_spins()
			hint_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))


func _refresh_icons() -> void:
	for child in part_icons.get_children():
		child.queue_free()

	if machine == null:
		return

	if machine.frame and machine.frame.icon_path != "":
		_add_icon(machine.frame.icon_path)

	for i in range(machine.reels.size()):
		_add_icon(REEL_ICON_PATH)

	for lever in machine.levers:
		if lever.icon_path != "":
			_add_icon(lever.icon_path)

	for mod in machine.modifiers:
		if mod.icon_path != "":
			_add_icon(mod.icon_path)


func _add_icon(path: String) -> void:
	var tex = load(path)
	if tex == null:
		return
	var rect := TextureRect.new()
	rect.texture = tex
	rect.custom_minimum_size = Vector2(PART_ICON_SIZE, PART_ICON_SIZE)
	rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	part_icons.add_child(rect)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()
