extends PanelContainer

signal clicked()

var machine: Machine = null

@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel
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

	if machine == null:
		status_label.text = "[ Empty Slot ]"
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


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit()
