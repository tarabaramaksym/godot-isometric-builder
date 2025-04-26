class_name NatureUI extends Control

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
	title.text = "Nature Components"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	component_container.add_child(title)
	
	# Load components from global
	var components = GlobalFileNature.load_nature_data()
	
	# Generate UI for each component
	for component_key in components.keys():
		add_component_button(component_key)

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
	if component_name == GlobalBuilding.selected_component:
		GlobalBuilding.set_selected_component("")
		return

	print("Selected workstation: ", component_name)
	GlobalBuilding.set_selected_component(component_name)
	
	# Get reference to workstation builder and update size options
	var nature_builder = get_node("/root/Main/BuildingBuilder")  # Adjust path as needed
	if nature_builder:
		nature_builder.update_size_options(component_name)

func _on_mouse_entered():
	GlobalBuilding.set_ui_interaction(true)

func _on_mouse_exited():
	GlobalBuilding.set_ui_interaction(false)
