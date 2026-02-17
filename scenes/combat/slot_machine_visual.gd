extends PanelContainer

signal spin_requested(machine: Machine)

var machine: Machine = null

@onready var machine_label: Label = $MarginContainer/VBoxContainer/MachineLabel
@onready var reel_container: HBoxContainer = $MarginContainer/VBoxContainer/ReelContainer
@onready var info_hbox: HBoxContainer = $MarginContainer/VBoxContainer/InfoHBox
@onready var spins_label: Label = $MarginContainer/VBoxContainer/InfoHBox/SpinsLabel
@onready var spin_button: Button = $MarginContainer/VBoxContainer/InfoHBox/SpinButton
@onready var result_label: Label = $MarginContainer/VBoxContainer/ResultLabel

var _reel_visual_scene: PackedScene = preload("res://scenes/combat/reel_visual.tscn")


func setup(m: Machine) -> void:
	machine = m


func _ready() -> void:
	if machine:
		machine_label.text = machine.id.to_upper().replace("_", " ")
		_update_spins()
		result_label.text = ""
		for i in range(machine.reels.size()):
			var reel_visual := _reel_visual_scene.instantiate()
			reel_container.add_child(reel_visual)


func get_machine() -> Machine:
	return machine


func show_results(results: Array, points: int) -> void:
	for i in range(mini(results.size(), reel_container.get_child_count())):
		var reel_visual := reel_container.get_child(i)
		if reel_visual.has_method("show_symbol"):
			reel_visual.show_symbol(results[i])

	if points > 0:
		result_label.text = "+%d points!" % points
		result_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	else:
		result_label.text = "No match"
		result_label.add_theme_color_override("font_color", Color(0.7, 0.4, 0.4))

	_update_spins()

	if machine.spins_remaining <= 0:
		spin_button.disabled = true
		spin_button.text = "Exhausted"


func _update_spins() -> void:
	if machine:
		spins_label.text = "Spins: %d" % machine.spins_remaining


func _on_spin_button_pressed() -> void:
	if machine and machine.spins_remaining > 0:
		spin_requested.emit(machine)
