extends Node

var resource_json_path = "res://assets/json/resource/resource.json"
var resource_parent_json_path = "res://assets/json/resource/resource_parent.json"
var cached_resources = null
var cached_resource_parents = null

func get_resource_data(resource_id: String) -> Dictionary:
    # Load resources if not already loaded
    if cached_resources == null:
        load_resources()
    
    if cached_resources != null and cached_resources.has(resource_id):
        return cached_resources[resource_id]
    
    return {}

func get_resource_parent_data(parent_id: String) -> Dictionary:
    # Load parent resources if not already loaded
    if cached_resource_parents == null:
        load_resource_parents()
    
    if cached_resource_parents != null and cached_resource_parents.has(parent_id):
        return cached_resource_parents[parent_id]
    
    return {}

func load_resources() -> Dictionary:
    if cached_resources != null:
        return cached_resources
        
    cached_resources = _load_json_file(resource_json_path)
    return cached_resources

func load_resource_parents() -> Dictionary:
    if cached_resource_parents != null:
        return cached_resource_parents
        
    cached_resource_parents = _load_json_file(resource_parent_json_path)
    return cached_resource_parents

func _load_json_file(file_path: String) -> Dictionary:
    var file = FileAccess.open(file_path, FileAccess.READ)
    if file:
        var json_text = file.get_as_text()
        file.close()
        
        var json = JSON.new()
        var error = json.parse(json_text)
        if error == OK:
            return json.data
        else:
            print("JSON Parse Error: ", json.get_error_message(), " at line ", json.get_error_line())
    else:
        print("Failed to open file: ", file_path)
    
    return {}

func clear_cache():
    cached_resources = null
    cached_resource_parents = null