extends Node

var cached_input_data = null
var input_json_path = "res://assets/json/input/resource_input.json"

func load_input_data():
    if cached_input_data != null:  
        return cached_input_data
        
    # Otherwise load from file
    var file = FileAccess.open(input_json_path, FileAccess.READ)
    if file:
        var json_text = file.get_as_text()
        file.close()
        
        var json = JSON.new()
        var error = json.parse(json_text)
        if error == OK:
            # Cache the loaded data
            cached_input_data = json.data
            return cached_input_data
        else:
            print("JSON Parse Error: ", json.get_error_message(), " at line ", json.get_error_line())
    else:
        print("Failed to open file: ", input_json_path)
    
    return {}

func get_input_data(input_id: String):
    if !cached_input_data:
        load_input_data()
        
    return cached_input_data.get(input_id, null)

func clear_cache():
    cached_input_data = null