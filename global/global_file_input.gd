extends Node

var cached_input_data = null
var input_directory = "res://assets/json/input/"

func load_input_data():
    if cached_input_data != null:  
        return cached_input_data
    
    cached_input_data = {}
    
    # Get list of all JSON files in the directory
    var dir = DirAccess.open(input_directory)
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        
        while file_name != "":
            if file_name.ends_with(".json"):
                var file_path = input_directory + file_name
                load_input_file(file_path)
            file_name = dir.get_next()
    else:
        print("Failed to open directory: ", input_directory)
    
    process_inheritance()
    return cached_input_data

func load_input_file(file_path: String):
    var file = FileAccess.open(file_path, FileAccess.READ)
    if file:
        var json_text = file.get_as_text()
        file.close()
        
        var json = JSON.new()
        var error = json.parse(json_text)
        if error == OK:
            # Merge with existing data
            var file_data = json.data
            for key in file_data.keys():
                cached_input_data[key] = file_data[key]
        else:
            print("JSON Parse Error in ", file_path, ": ", json.get_error_message(), " at line ", json.get_error_line())
    else:
        print("Failed to open file: ", file_path)

func process_inheritance():
    for key in cached_input_data.keys():
        var input_data = cached_input_data[key]
        
        # Handle inheritance
        if "inherit" in input_data:
            cached_input_data[key] = inherit_data(input_data)

func inherit_data(input_data: Dictionary) -> Dictionary:
    var inherit = input_data.get("inherit")
    if not inherit or not cached_input_data.has(inherit):
        return input_data
        
    var parent_data = cached_input_data.get(inherit).duplicate(true)
    
    # Check if parent has inheritance as well and process it first
    if "inherit" in parent_data:
        parent_data = inherit_data(parent_data)
    
    return _deep_merge(parent_data, input_data)

func _deep_merge(target: Dictionary, source: Dictionary) -> Dictionary:
    for key in source:
        if key == "inherit":
            continue
            
        if key in target and source[key] is Dictionary and target[key] is Dictionary:
            _deep_merge(target[key], source[key])
        else:
            target[key] = source[key]
    
    return target

func get_input_data(input_id: String):
    if !cached_input_data:
        load_input_data()
        
    return cached_input_data.get(input_id, null)

func clear_cache():
    cached_input_data = null