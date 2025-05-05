extends Node

# Add this signal declaration at the top
signal ui_interaction_changed(is_active)
signal selected_component_changed(component_name)

var selected_component = ""
var building_mode = false
var ui_interaction = false

var target_small_gridmap = false

func set_ui_interaction(value: bool):
    ui_interaction = value
    emit_signal("ui_interaction_changed", value)

func set_selected_component(value: String):
    selected_component = value

    var data = GlobalDataManager.get_game_object(value)

    if data.base_mesh_size[0] == 0.2 and data.base_mesh_size[2] == 0.2:
        target_small_gridmap = true
    else:
        target_small_gridmap = false

    emit_signal("selected_component_changed", value)

