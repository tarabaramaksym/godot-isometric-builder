class_name BuildingGameObject extends GameObject

func initialize_game_object(game_object_id_param: String, parameters: Dictionary):
    super.initialize_game_object(game_object_id_param, parameters)

    var shifted = parameters.get("shifted", false)

    setup_and_position_static_body(parameters.body_position, parameters.rotation, parameters.current_size_values, shifted)

func save() -> Dictionary:
    var save_data = super.save()
    save_data["type"] = "BuildingGameObject"
    return save_data
