class_name InteractiveGameObject extends BuildingGameObject

var input_point : Node3D
var output_point : Node3D

var interaction_handler: InteractionHandler

var input_data: Dictionary = {}

var is_recipe: bool = false
var recipe_inputs: Dictionary = {}

var is_processing_interaction: bool = false
var finished_processing: bool = false
var processed_items: Array = []

func initialize_game_object(game_object_id_param: String, parameters: Dictionary):
    super.initialize_game_object(game_object_id_param, parameters)

    var input_position = component_data.input_position
    var output_position = component_data.output_position
    var possible_inputs = component_data.input

    for input in possible_inputs:
        var data = GlobalDataManager.get_input(input)
        input_data[input] = data
        
        if data.get("type") == "recipe":
            is_recipe = true
            recipe_inputs[input] = data

    input_point = Node3D.new()
    input_point.position = Vector3(input_position[0], input_position[1], input_position[2])
    add_child(input_point)

    output_point = Node3D.new()
    output_point.position = Vector3(output_position[0], output_position[1], output_position[2])
    add_child(output_point)

func handle_interaction(interacter: Node3D, parameters: Dictionary):
    if is_processing_interaction:
        return

    if finished_processing:
        finished_processing = false

        for item in processed_items:
            var item_id = item.get("item_id")
            var item_quantity = item.get("item_quantity")
            interacter.inventory.add_item_by_id(item_id, item_quantity)

        processed_items = []

        return
        
    if interaction_handler:
        interaction_handler.handle_interaction(self, interacter, parameters)

func finish_processing(output: Dictionary):
    var items = output.get("item")
        
    for item in items.values():
        var item_id = item.get("item_key")
        var item_quantity = item.get("quantity")
        processed_items.append({"item_id": item_id, "item_quantity": item_quantity})
    finished_processing = true

func inherit_data(input_data_arg: Dictionary) -> Dictionary:
    var inherit = input_data_arg.get("inherit")
    var parent_data = GlobalDataManager.get_input(inherit)
    
    var merged_data = parent_data.duplicate(true)
    
    return _deep_merge(merged_data, input_data_arg)

func _deep_merge(target: Dictionary, source: Dictionary) -> Dictionary:
    for key in source:
        if key == "inherit":
            continue
            
        if key in target and source[key] is Dictionary and target[key] is Dictionary:
            _deep_merge(target[key], source[key])
        else:
            target[key] = source[key]
    
    return target

func save() -> Dictionary:
    var save_data = super.save()
    save_data["type"] = "InteractiveGameObject"
    
    return save_data
