extends Control

var component_json_path = "res://assets/json/building/house-components.json"
var component_container: VBoxContainer

func _ready():
	# Create main container
	component_container = VBoxContainer.new()
	component_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(component_container)
	
	# Set up mouse enter/exit detection for the entire UI
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Add title
	var title = Label.new()
	title.text = "Building Components"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	component_container.add_child(title)
	
	# Load and parse the JSON file
	var components = load_component_data()
	
	# Generate UI for each component
	for component_key in components.keys():
		add_component_button(component_key)

func load_component_data():
	var file = FileAccess.open(component_json_path, FileAccess.READ)
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
		print("Failed to open file: ", component_json_path)
	
	return {}

func add_component_button(component_name):
	var button = Button.new()
	button.text = component_name
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 40)
	
	button.pressed.connect(_on_component_button_pressed.bind(component_name))
	
	# Add mouse enter/exit detection to each button
	button.mouse_entered.connect(_on_mouse_entered)
	button.mouse_exited.connect(_on_mouse_exited)
	
	component_container.add_child(button)

func _on_component_button_pressed(component_name):
	print("Selected component: ", component_name)
	GlobalBuilding.selected_component = component_name
	
	# Get reference to building builder and update size options
	var building_builder = get_node("/root/Main/BuildingBuilder")  # Adjust path as needed
	if building_builder:
		building_builder.update_size_options(component_name)

func _on_mouse_entered():
	GlobalBuilding.ui_interaction = true

func _on_mouse_exited():
	GlobalBuilding.ui_interaction = false
