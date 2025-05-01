class_name InteractiveGameObject extends BuildingGameObject

var input_point : Node3D
var output_point : Node3D

var inputs: Array[GameInput] = []

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
    var distance = interacter.global_position.distance_to(input_point.global_position)
    print(distance)
    if distance < GlobalConfig.action_proximity:
        print('hello')
        # trigger interaction
        pass
    else:
        interacter.move_to(input_point.global_position, handle_interaction.bind(interacter, parameters))
