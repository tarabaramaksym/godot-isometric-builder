extends Node

var game_object_data = null
var input_data = null

var base_path = "res://assets/json/"

var game_object_folder_paths = [
    "building/",
    "item/"
]

var input_folder_paths = [
    "input/"
]

func initialize_data():
    game_object_data = load_data(game_object_folder_paths)
    input_data = load_data(input_folder_paths)

func load_data(folder_paths: Array):
    var data = {}
    
    for folder_path in folder_paths:
        var dir_path = base_path + folder_path
        var dir = DirAccess.open(dir_path)
        
        if dir:
            dir.list_dir_begin()
            var file_name = dir.get_next()
            
            while file_name != "":
                if not dir.current_is_dir() and file_name.ends_with(".json"):
                    var file_path = dir_path + file_name
                    var json_data = load_json_file(file_path)
                    
                    if json_data:
                        for child_key in json_data.keys():
                            data[child_key] = json_data[child_key]
                
                file_name = dir.get_next()
            
            dir.list_dir_end()
    
    return data

func load_json_file(file_path):
    var file = FileAccess.open(file_path, FileAccess.READ)
    if not file:
        push_error("Could not open file: " + file_path)
        return null
    
    var json_text = file.get_as_text()
    var json = JSON.new()
    var error = json.parse(json_text)
    
    if error != OK:
        push_error("JSON parse error: " + json.get_error_message() + " in " + file_path + " at line " + str(json.get_error_line()))
        return null
    
    return json.get_data()

func get_input(input_id: String):
    if input_data == null:
        initialize_data()
    
    if input_data.has(input_id):
        return input_data[input_id]
    

func get_game_object(object_id: String):
    if game_object_data == null:
        initialize_data()
    
    if game_object_data.has(object_id):
        return game_object_data[object_id]
    
    return null

func get_game_object_data():
    if game_object_data == null:
        initialize_data()
    
    return game_object_data


