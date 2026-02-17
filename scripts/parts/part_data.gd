class_name PartData
extends Resource

@export var id: String
@export var display_name: String
@export var description: String
@export var category: String  # "structural" or "modifier"
@export var type: String      # FRAME, REEL, LEVER, ADD_SYMBOL, CHANGE_WEIGHT, SCORE_MULTIPLIER
@export var cost: int
@export var params: Dictionary


static func from_dict(data: Dictionary) -> PartData:
	var part := PartData.new()
	part.id = data.get("id", "")
	part.display_name = data.get("name", "")
	part.description = data.get("description", "")
	part.category = data.get("category", "")
	part.type = data.get("type", "")
	part.cost = data.get("cost", 0)
	part.params = data.get("params", {})
	return part
