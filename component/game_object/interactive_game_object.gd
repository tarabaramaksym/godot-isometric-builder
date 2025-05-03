class_name InteractiveGameObject extends BuildingGameObject

var input_point : Node3D
var output_point : Node3D

var interaction_handler: InteractionHandler

func initialize_game_object(game_object_id_param: String, parameters: Dictionary):
    super.initialize_game_object(game_object_id_param, parameters)

    var input_position = component_data.input_position
    var output_position = component_data.output_position

    input_point = Node3D.new()
    input_point.position = Vector3(input_position[0], input_position[1], input_position[2])
    add_child(input_point)

    output_point = Node3D.new()
    output_point.position = Vector3(output_position[0], output_position[1], output_position[2])
    add_child(output_point)

func handle_interaction(interacter: Node3D, parameters: Dictionary):
    if interaction_handler:
        interaction_handler.handle_interaction(self, interacter, parameters)
    else:
        push_error("No interaction_handler assigned to this InteractiveGameObject")

func save() -> Dictionary:
    var save_data = super.save()
    save_data["type"] = "InteractiveGameObject"
    
    return save_data
