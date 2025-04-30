class_name InteractiveGameObject extends BuildingGameObject

var input_point : Node3D
var output_point : Node3D

var inputs: Array[GameInput] = []

func initialize_game_object(game_object_id_param: String, parameters: Dictionary):
    super.initialize_game_object(game_object_id_param, parameters)
