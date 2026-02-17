extends PanelContainer

signal purchased(part: PartData)

var part: PartData

@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel
@onready var desc_label: Label = $MarginContainer/VBoxContainer/DescLabel
@onready var cost_label: Label = $MarginContainer/VBoxContainer/CostLabel
@onready var buy_button: Button = $MarginContainer/VBoxContainer/BuyButton


func setup(p: PartData) -> void:
	part = p


func _ready() -> void:
	if part:
		name_label.text = part.display_name
		desc_label.text = part.description
		cost_label.text = "%d coins" % part.cost
		_update_category_color()
		update_affordability(GameManager.coins)


func _update_category_color() -> void:
	if part and part.category == "structural":
		name_label.add_theme_color_override("font_color", Color(0.6, 0.85, 1.0))
	elif part and part.category == "modifier":
		name_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))


func update_affordability(current_coins: int) -> void:
	if part:
		buy_button.disabled = current_coins < part.cost


func _on_buy_button_pressed() -> void:
	purchased.emit(part)
