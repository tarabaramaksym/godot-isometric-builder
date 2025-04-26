class_name InteractionWorkstation extends Node

@export var workstation_interaction_ui: WorkstationInteractionUI

func handle_interaction(component_data: Dictionary, click_type: String):
	if click_type == "left":
		workstation_interaction_ui.prepare_and_show_ui(component_data)
