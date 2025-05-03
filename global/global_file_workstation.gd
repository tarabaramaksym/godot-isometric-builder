extends Node

var cached_workstations = null
var workstation_json_path = "res://assets/json/building/workstation.json"

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
			process_inheritance()
		else:
			print("JSON Parse Error: ", json.get_error_message(), " at line ", json.get_error_line())
	else:
		print("Failed to open file: ", workstation_json_path)
	
	return cached_workstations

func process_inheritance():
	for key in cached_workstations.keys():
		var workstation = cached_workstations[key]
		
		workstation.interaction_type = "workstation"
		workstation.can_be_highlighted = true
		workstation.can_be_interacted = true
		
		# Handle inheritance
		if "inherit" in workstation:
			var parent_key = workstation.inherit
			var parent_data = cached_workstations.get(parent_key)
			
			if parent_data:
				cached_workstations[key] = inherit_data(workstation)

func inherit_data(workstation: Dictionary) -> Dictionary:
	var inherit = workstation.get("inherit")
	if not inherit or not cached_workstations.has(inherit):
		return workstation
		
	var parent_data = cached_workstations.get(inherit).duplicate(true)
	
	return _deep_merge(parent_data, workstation)

func _deep_merge(target: Dictionary, source: Dictionary) -> Dictionary:
	for key in source:
		if key == "inherit":
			continue
			
		if key in target and source[key] is Dictionary and target[key] is Dictionary:
			_deep_merge(target[key], source[key])
		else:
			target[key] = source[key]
	
	return target

func clear_cache():
	cached_workstations = null
