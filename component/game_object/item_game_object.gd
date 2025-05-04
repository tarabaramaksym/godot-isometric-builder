class_name ItemGameObject extends GameObject

var stackable: bool
var has_quality: bool
var type: Array
var description: String
var icon: String
var weight: float
var base_value: float

#tmp
var quantity: int

func initialize_game_object(game_object_id_param: String, parameters: Dictionary):
	super.initialize_game_object(game_object_id_param, parameters)

	var data = GlobalDataManager.get_input(game_object_id_param)

	if !data:
		return

	stackable = data.get("stackable", false)
	has_quality = data.get("has_quality", false)
	type = data.get("type", [])
	description = data.get("description", "")
	icon = data.get("icon", "")
	weight = data.get("weight", 0.0)
	base_value = data.get("base_value", 0.0)
