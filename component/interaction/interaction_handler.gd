class_name InteractionHandler extends Node

@export var workstation_interaction: InteractionWorkstation
@export var nature_interaction: InteractionNature

func handle_interaction(static_body: StaticBody3D, click_type: String):
	var component_data = static_body.get_meta("component_data")

	if !component_data:
		return

	if !"can_be_interacted" in component_data or !component_data.can_be_interacted:
		return

	if component_data.interaction_type == "workstation":
		workstation_interaction.handle_interaction(component_data, click_type)
	elif component_data.interaction_type == "nature":
		nature_interaction.handle_interaction(component_data, click_type)

