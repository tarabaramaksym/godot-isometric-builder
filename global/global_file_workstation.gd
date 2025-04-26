extends Node

var cached_workstations = null
var parent_workstations = null
var workstation_json_path = "res://assets/json/building/workstation.json"
var workstation_parent_json_path = "res://assets/json/building/workstation_parent.json"

func load_workstation_data():
	if cached_workstations != null:
		return cached_workstations
		
	# Otherwise load from file
	var file = FileAccess.open(workstation_json_path, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_text)
		if error == OK:
			# Cache the loaded data
			cached_workstations = json.data
		else:
			print("JSON Parse Error: ", json.get_error_message(), " at line ", json.get_error_line())
	else:
		print("Failed to open file: ", workstation_json_path)
	
	load_parent_workstation_data()

	assign_parent_data()
	
	return cached_workstations

func load_parent_workstation_data():
	if parent_workstations != null:
		return parent_workstations
		
	# Otherwise load from file
	var file = FileAccess.open(workstation_parent_json_path, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_text)
		if error == OK:
			# Cache the loaded data
			parent_workstations = json.data
			return parent_workstations
		else:
			print("JSON Parse Error: ", json.get_error_message(), " at line ", json.get_error_line())
	else:
		print("Failed to open file: ", workstation_parent_json_path)
	
	return parent_workstations
		
func assign_parent_data():
	for key in cached_workstations.keys():
		var value = cached_workstations[key]
		value.is_workstation = true
		value.can_be_highlighted = true

		if "inherits" in value:
			var parent_data = parent_workstations.get(value.inherits)

			if !parent_data:
				continue
			
			if "workstation_properties" in value:
				value.workstation_properties.merge(parent_data)
			else:
				value.workstation_properties = parent_data

func clear_cache():
	cached_workstations = null
	parent_workstations = null
