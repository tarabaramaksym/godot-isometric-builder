class_name InteractionNature extends Node

func handle_interaction(component_data: Dictionary, click_type: String):
	var resource_key = component_data.resource
	var resource = GlobalFileResource.get_resource_data(resource_key)

	if resource_key:
		var game_resource = GameResource.new(resource_key, 1, 1)
		GlobalPlayer.player.inventory.add_item(game_resource)
