extends Node

var cached_building_components = null
var component_json_path = "res://assets/json/building/house-component.json"

func load_component_data():
    if cached_building_components != null:
        return cached_building_components
        
    # Otherwise load from file
    var file = FileAccess.open(component_json_path, FileAccess.READ)
    if file:
        var json_text = file.get_as_text()
        file.close()
        
        var json = JSON.new()
        var error = json.parse(json_text)
        if error == OK:
            # Cache the loaded data
            cached_building_components = json.data
            return cached_building_components
        else:
            print("JSON Parse Error: ", json.get_error_message(), " at line ", json.get_error_line())
    else:
        print("Failed to open file: ", component_json_path)
    
    return {}

func clear_cache():
    cached_building_components = null