class_name InteractionHandler extends Node

@export var interaction_recipe: InteractionRecipe

func handle_interaction(game_object: InteractiveGameObject, interacter: Node3D, parameters: Dictionary):
	var distance = interacter.global_position.distance_to(game_object.input_point.global_position)
	var distance_margin = game_object.component_data.get("distance_margin", 0)

	if distance < (GlobalConfig.action_proximity + distance_margin):
		var possible_inputs = game_object.component_data.input
		var is_recipe = false
		var possible_recipe_inputs = {}

		for input in possible_inputs:
			var input_data = GlobalFileInput.get_input_data(input)
			
			if input_data.get("type") == "recipe":
				possible_recipe_inputs[input] = input_data
				is_recipe = true

		if is_recipe and interacter is Player:
			launch_recipe(game_object, interacter, possible_recipe_inputs)
		else:
			for input in possible_inputs:
				var input_data = GlobalFileInput.get_input_data(input)

				if input_data.get("inherit"):
					input_data = inherit_data(input_data)

				if can_interact(interacter, input_data):
					launch_interaction(game_object, interacter, input_data)
				else:
					print("cannot interact")
				pass
	else:
		interacter.move_to(game_object.input_point.global_position, handle_interaction.bind(game_object, interacter, parameters))

func launch_recipe(_game_object: InteractiveGameObject, interacter: Node3D, recipe_inputs: Dictionary):
	interaction_recipe.launch_recipe(interacter, recipe_inputs)
	interacter.lock_interaction(interaction_recipe.hide_ui)

func launch_interaction(game_object: InteractiveGameObject, interacter: Node3D, input_data: Dictionary):
	var type = input_data.get("type")

	if type == "action":
		# TODO: Will be replace with more specific option beforehand
		for input in input_data.get("inputs", {}).values():
			var input_tool = input.get("tool")

			if input_tool:
				if interacter.inventory.has_item(input_tool):
					var action_data = input
					launch_action(game_object, interacter, input_data, action_data)
			
		pass
	elif type == "recipe":
		# Only for NPCs, player goes through the recipe UI
		pass

func inherit_data(input_data: Dictionary):
	var inherit = input_data.get("inherit")
	var parent_data = GlobalFileInput.get_input_data(inherit)
	
	var merged_data = parent_data.duplicate(true)
	
	return _deep_merge(merged_data, input_data)

func _deep_merge(target: Dictionary, source: Dictionary) -> Dictionary:
	for key in source:
		if key == "inherit":
			continue
			
		if key in target and source[key] is Dictionary and target[key] is Dictionary:
			_deep_merge(target[key], source[key])
		else:
			target[key] = source[key]
	
	return target

func can_interact(interacter: Node3D, input_data: Dictionary):
	var inputs : Dictionary = input_data.get("inputs", {})

	for input in inputs.values():
		if input.get("type") == "character":
			var input_tool = input.get("tool")

			if input_tool:
				if interacter.inventory.has_item(input_tool):
					return true
				else:
					return false
			else:
				return true

		return true

func launch_action(game_object: InteractiveGameObject, interacter: Node3D, input_data: Dictionary, action_data: Dictionary):
	var action_time = action_data.get("action_time", 0)
	var process_time = action_data.get("process_time", 0)
	
	var output = action_data.get("output", {})

	if process_time == 0:
		if output.get("type") == "item":
			var timer_id = GlobalTimer.add_timer(action_time, add_item_on_end.bind(game_object, interacter, input_data, output))
			interacter.lock_interaction(GlobalTimer.remove_timer.bind(timer_id))
	elif action_time == 0:
		# TODO: launch process
		pass
	else:
		# launch action first
		# launch process after action
		pass

func add_item_on_end(game_object: InteractiveGameObject, interacter: Node3D, input_data: Dictionary, output: Dictionary):
	var onend = input_data.get("onend")
	var item_array = output.get("item")

	for output_item_key in item_array.keys():
		var item_data = item_array.get(output_item_key)

		var item_id = item_data.get("item_key")
		var item_quantity = item_data.get("quantity")
		interacter.inventory.add_item_by_id(item_id, item_quantity)

	interacter.unlock_interaction()

	if onend == 'remove':
		game_object.queue_free()
