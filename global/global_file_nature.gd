extends Node

var cached_nature = null
var nature_json_path = "res://assets/json/building/nature.json"

func load_nature_data():
	if cached_nature != null:
		return cached_nature
		
	# Otherwise load from file
	var file = FileAccess.open(nature_json_path, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_text)
		if error == OK:
			# Cache the loaded data
			cached_nature = json.data
		else:
			print("JSON Parse Error: ", json.get_error_message(), " at line ", json.get_error_line())
	else:
		print("Failed to open file: ", nature_json_path)

	for key in cached_nature.keys():
		var value = cached_nature[key]

		value.interaction_type = "nature"
		value.can_be_highlighted = true
		value.can_be_interacted = true
	
	return cached_nature

func clear_cache():
	cached_nature = null
