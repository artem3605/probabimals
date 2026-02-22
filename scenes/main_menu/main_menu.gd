extends Control

@onready var start_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/StartButton
@onready var exit_button: Button = $CenterContainer/VBoxContainer/ButtonContainer/ExitButton
@onready var title_label: Label = $CenterContainer/VBoxContainer/Title


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	start_button.grab_focus()
	_animate_title_glow()


func _animate_title_glow() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(
		title_label, "theme_override_colors/font_color",
		Color(1.0, 0.95, 0.4, 1.0), 2.0
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
		title_label, "theme_override_colors/font_color",
		Color(1.0, 0.84, 0.0, 1.0), 2.0
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_start_pressed() -> void:
	pass # TODO: transition to FleaMarket scene


func _on_exit_pressed() -> void:
	get_tree().quit()
