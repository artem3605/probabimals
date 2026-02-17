extends PanelContainer

@onready var symbol_label: Label = $CenterContainer/SymbolLabel


func _ready() -> void:
	symbol_label.text = "?"


func show_symbol(symbol_id: String) -> void:
	var symbol_data := DataManager.get_symbol(symbol_id)
	symbol_label.text = symbol_data.get("name", symbol_id)
