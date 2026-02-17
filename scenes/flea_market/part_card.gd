extends PanelContainer

signal selected(part: PartData, card: Node)

var part: PartData
var is_selected: bool = false

@onready var icon_rect: TextureRect = $MarginContainer/VBoxContainer/IconRect
@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel
@onready var type_label: Label = $MarginContainer/VBoxContainer/TypeLabel


func setup(p: PartData) -> void:
	part = p


func _ready() -> void:
	if part:
		name_label.text = part.display_name
		type_label.text = "[%s]" % part.type
		_load_icon()
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _load_icon() -> void:
	if part and part.icon_path != "":
		var tex = load(part.icon_path)
		if tex:
			icon_rect.texture = tex


func get_part() -> PartData:
	return part


func set_selected(value: bool) -> void:
	is_selected = value
	if is_selected:
		modulate = Color(1.2, 1.2, 0.8)
	else:
		modulate = Color(1, 1, 1)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected.emit(part, self)
