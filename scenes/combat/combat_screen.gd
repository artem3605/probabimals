extends Control

@onready var score_label: Label = %ScoreLabel
@onready var end_combat_button: Button = %EndCombatButton
@onready var machine_field: VBoxContainer = %CombatMachineField
@onready var result_overlay: ColorRect = %ResultOverlay
@onready var final_score_label: Label = %FinalScoreLabel
@onready var menu_button: Button = %MenuButton

var combat_manager: CombatManager

var _machine_visual_scene: PackedScene = preload("res://scenes/combat/slot_machine_visual.tscn")


func _ready() -> void:
	result_overlay.visible = false
	combat_manager = CombatManager.new()
	add_child(combat_manager)
	combat_manager.combat_ended.connect(_on_combat_ended)
	combat_manager.machine_spun.connect(_on_machine_spun)
	combat_manager.start_combat()
	_populate_machines()
	_update_score()


func _populate_machines() -> void:
	for machine in GameManager.machines:
		if machine.is_complete():
			var visual := _machine_visual_scene.instantiate()
			visual.setup(machine)
			visual.spin_requested.connect(_on_spin_requested)
			machine_field.add_child(visual)


func _on_spin_requested(machine: Machine) -> void:
	combat_manager.spin_machine(machine)


func _on_machine_spun(machine: Machine, results: Array, points: int) -> void:
	_update_score()
	for child in machine_field.get_children():
		if child.has_method("get_machine") and child.get_machine() == machine:
			child.show_results(results, points)
			break


func _update_score() -> void:
	score_label.text = "Score: %d" % combat_manager.running_score


func _on_combat_ended(final_score: int) -> void:
	result_overlay.visible = true
	final_score_label.text = "Final Score: %d" % final_score
	end_combat_button.disabled = true


func _on_end_combat_button_pressed() -> void:
	combat_manager.end_combat()


func _on_menu_button_pressed() -> void:
	GameManager.end_combat()
