extends Control

@onready var coin_label: Label = %CoinLabel
@onready var combat_button: Button = %CombatButton
@onready var shop_grid: GridContainer = %ShopGrid
@onready var hand_grid: HBoxContainer = %HandGrid
@onready var machine_field: VBoxContainer = %MachineField

var selected_part: PartData = null
var selected_card: Node = null

var _shop_item_scene: PackedScene = preload("res://scenes/flea_market/shop_item.tscn")
var _part_card_scene: PackedScene = preload("res://scenes/flea_market/part_card.tscn")
var _machine_slot_scene: PackedScene = preload("res://scenes/flea_market/machine_slot.tscn")


func _ready() -> void:
	_populate_shop()
	_update_coins()
	_update_combat_button()
	_add_machine_slot()
	GameManager.coins_changed.connect(_on_coins_changed)


func _populate_shop() -> void:
	var catalogue := DataManager.get_shop_catalogue()
	for part in catalogue:
		var item := _shop_item_scene.instantiate()
		item.setup(part)
		item.purchased.connect(_on_part_purchased)
		shop_grid.add_child(item)


func _on_part_purchased(part: PartData) -> void:
	if GameManager.buy_part(part):
		_add_part_to_hand(part)
		_update_combat_button()


func _add_part_to_hand(part: PartData) -> void:
	var card := _part_card_scene.instantiate()
	card.setup(part)
	card.selected.connect(_on_hand_part_selected)
	hand_grid.add_child(card)


func _on_hand_part_selected(part: PartData, card: Node) -> void:
	selected_part = part
	selected_card = card
	for child in hand_grid.get_children():
		if child.has_method("set_selected"):
			child.set_selected(child == card)


func _on_machine_slot_clicked(slot: Node) -> void:
	if selected_part == null:
		return

	if selected_part.type == "FRAME":
		if not slot.has_machine():
			var machine := GameManager.create_machine(selected_part)
			GameManager.remove_part_from_hand(selected_part)
			_remove_selected_from_hand()
			slot.setup_machine(machine)
			_add_machine_slot()
			_update_combat_button()
	elif slot.has_machine():
		var machine: Machine = slot.get_machine()
		if GameManager.attach_part_to_machine(selected_part, machine):
			GameManager.remove_part_from_hand(selected_part)
			_remove_selected_from_hand()
			slot.update_display()
			_update_combat_button()


func _remove_selected_from_hand() -> void:
	if selected_card and is_instance_valid(selected_card):
		selected_card.queue_free()
	selected_part = null
	selected_card = null


func _add_machine_slot() -> void:
	var slot := _machine_slot_scene.instantiate()
	slot.clicked.connect(_on_machine_slot_clicked.bind(slot))
	machine_field.add_child(slot)


func _update_coins() -> void:
	coin_label.text = "Coins: %d" % GameManager.coins


func _on_coins_changed(_amount: int) -> void:
	_update_coins()
	for item in shop_grid.get_children():
		if item.has_method("update_affordability"):
			item.update_affordability(GameManager.coins)


func _update_combat_button() -> void:
	combat_button.disabled = not GameManager.has_complete_machine()


func _on_combat_button_pressed() -> void:
	GameManager.go_to_combat()
