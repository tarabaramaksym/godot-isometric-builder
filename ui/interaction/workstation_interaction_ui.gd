class_name WorkstationInteractionUI extends Control

var is_visible = false
var workstation_data: Dictionary
var player_inventory: Inventory

# UI Components
var main_container: VBoxContainer
var input_output_container: HBoxContainer
var inputs_list: VBoxContainer
var output_panel: VBoxContainer
var close_button: Button
var filter_checkbox: CheckBox

# Current selection
var selected_input_key: String = ""

func _ready():
	player_inventory = GlobalPlayer.player.inventory
	
	# Make UI take up full screen
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	# Fully opaque background instead of semi-transparent
	var panel_bg = Panel.new()
	panel_bg.anchor_right = 1.0
	panel_bg.anchor_bottom = 1.0
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.18, 1.0)  # Dark blue-gray, fully opaque
	panel_bg.add_theme_stylebox_override("panel", style)
	z_index = 100
	add_child(panel_bg)
	
	# Main container
	main_container = VBoxContainer.new()
	main_container.anchor_right = 1.0
	main_container.anchor_bottom = 1.0
	main_container.size_flags_horizontal = SIZE_EXPAND_FILL
	main_container.size_flags_vertical = SIZE_EXPAND_FILL
	main_container.add_theme_constant_override("separation", 20)
	add_child(main_container)
	
	# Header with title and close button
	var header = HBoxContainer.new()
	header.size_flags_horizontal = SIZE_EXPAND_FILL
	main_container.add_child(header)
	
	var title = Label.new()
	title.text = "Workstation"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 24)
	header.add_child(title)
	
	close_button = Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(_on_close_button_pressed)
	header.add_child(close_button)
	
	# Filter checkbox
	filter_checkbox = CheckBox.new()
	filter_checkbox.text = "Show only craftable recipes"
	#filter_checkbox.pressed = true
	filter_checkbox.toggled.connect(_on_filter_toggled)
	main_container.add_child(filter_checkbox)
	
	# Input-Output container
	input_output_container = HBoxContainer.new()
	input_output_container.size_flags_horizontal = SIZE_EXPAND_FILL
	input_output_container.size_flags_vertical = SIZE_EXPAND_FILL
	main_container.add_child(input_output_container)
	
	# Left side - Input list
	var input_panel = Panel.new()
	input_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	input_panel.size_flags_vertical = SIZE_EXPAND_FILL
	input_panel.size_flags_stretch_ratio = 0.4
	input_output_container.add_child(input_panel)
	
	var input_container = VBoxContainer.new()
	input_container.size_flags_horizontal = SIZE_EXPAND_FILL
	input_container.size_flags_vertical = SIZE_EXPAND_FILL
	input_panel.add_child(input_container)
	
	var input_title = Label.new()
	input_title.text = "Available Recipes"
	input_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	input_title.add_theme_font_size_override("font_size", 18)
	input_container.add_child(input_title)
	
	inputs_list = VBoxContainer.new()
	inputs_list.size_flags_horizontal = SIZE_EXPAND_FILL
	inputs_list.size_flags_vertical = SIZE_EXPAND_FILL
	input_container.add_child(inputs_list)
	
	# Right side - Output details
	var output_panel_bg = Panel.new()
	output_panel_bg.size_flags_horizontal = SIZE_EXPAND_FILL
	output_panel_bg.size_flags_vertical = SIZE_EXPAND_FILL
	output_panel_bg.size_flags_stretch_ratio = 0.6
	input_output_container.add_child(output_panel_bg)
	
	output_panel = VBoxContainer.new()
	output_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	output_panel.size_flags_vertical = SIZE_EXPAND_FILL
	output_panel.add_theme_constant_override("separation", 15)
	output_panel_bg.add_child(output_panel)
	
	var output_title = Label.new()
	output_title.text = "Recipe Details"
	output_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	output_title.add_theme_font_size_override("font_size", 18)
	output_panel.add_child(output_title)
	
	# Initially hide the UI
	visible = false

func prepare_and_show_ui(data: Dictionary):
	workstation_data = data
	
	# Update the title
	var title_label = main_container.get_child(0).get_child(0)
	title_label.text = workstation_data.name if "name" in workstation_data else "Workstation"
	
	# Clear previous inputs
	for child in inputs_list.get_children():
		child.queue_free()
	
	# Reset output panel
	_clear_output_panel()
	
	# Check if workstation has properties and recipes
	if "workstation_properties" in workstation_data:
		var properties = workstation_data.workstation_properties
		
		if "input" in properties:
			# Populate inputs based on filter
			_populate_input_list(properties.input, false)
	
	# Show the UI
	show_ui()

func _populate_input_list(inputs: Dictionary, filter_craftable: bool):
	# Sort inputs by key for consistency
	var input_keys = inputs.keys()
	input_keys.sort()
	
	for input_key in input_keys:
		var input_data = inputs[input_key]
		
		# Skip if filtering and not craftable
		if filter_craftable and not _is_craftable(input_data):
			continue
			
		# Create button for this input
		var input_button = Button.new()
		input_button.size_flags_horizontal = SIZE_EXPAND_FILL
		input_button.custom_minimum_size = Vector2(0, 40)
		
		# Get recipe requirements
		var req_text = ""
		if "resources" in input_data:
			for resource in input_data.resources:
				if req_text != "":
					req_text += ", "
				req_text += "%dx %s" % [resource.quantity, resource.resource_key]
		
		input_button.text = "%s (%s)" % [input_key, req_text]
		input_button.pressed.connect(_on_input_selected.bind(input_key))
		
		# Add visual indicator if craftable
		if _is_craftable(input_data):
			input_button.add_theme_color_override("font_color", Color(0.2, 0.8, 0.2))
		
		inputs_list.add_child(input_button)

func _is_craftable(input_data: Dictionary) -> bool:
	if not "resources" in input_data:
		return false
		
	# Check if player has all required resources
	for resource in input_data.resources:
		var resource_key = resource.resource_key
		var quantity_needed = resource.quantity
		
		# Check if player has enough
		var has_enough = false
		for item in player_inventory.items:
			if item.resource_id == resource_key and item.quantity >= quantity_needed:
				has_enough = true
				break
				
		if not has_enough:
			return false
	
	return true

func _on_input_selected(input_key: String):
	selected_input_key = input_key
	
	# Clear previous output info
	_clear_output_panel()
	
	# Get input details
	var input_data = workstation_data.workstation_properties.input[input_key]
	var output_key = input_data.output_key if "output_key" in input_data else ""
	var output_data = null
	
	if output_key != "" and "output" in workstation_data.workstation_properties:
		output_data = workstation_data.workstation_properties.output[output_key]
	
	# Add recipe title
	var recipe_title = Label.new()
	recipe_title.text = "Recipe: " + input_key
	recipe_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	recipe_title.add_theme_font_size_override("font_size", 20)
	output_panel.add_child(recipe_title)
	
	# Add time required
	var time_label = Label.new()
	time_label.text = "Time required: %d seconds" % [input_data.time if "time" in input_data else 0]
	output_panel.add_child(time_label)
	
	# Add required resources section
	var required_resources = Label.new()
	required_resources.text = "Required Resources:"
	required_resources.add_theme_font_size_override("font_size", 16)
	output_panel.add_child(required_resources)
	
	var resources_container = VBoxContainer.new()
	resources_container.add_theme_constant_override("separation", 5)
	output_panel.add_child(resources_container)
	
	if "resources" in input_data:
		for resource in input_data.resources:
			var resource_label = Label.new()
			var player_has = _get_player_resource_quantity(resource.resource_key)
			var color_tag = "[color=green]" if player_has >= resource.quantity else "[color=red]"
			
			resource_label.text = "- %s: %d/%d %s" % [resource.resource_key, player_has, resource.quantity, color_tag]
			resource_label.set_autowrap_mode(TextServer.AUTOWRAP_WORD_SMART)
			resources_container.add_child(resource_label)
	
	# Add output section
	var outputs_label = Label.new()
	outputs_label.text = "Output:"
	outputs_label.add_theme_font_size_override("font_size", 16)
	output_panel.add_child(outputs_label)
	
	var output_container = VBoxContainer.new()
	output_container.add_theme_constant_override("separation", 5)
	output_panel.add_child(output_container)
	
	if output_data and "resources" in output_data:
		for resource in output_data.resources:
			var output_item = Label.new()
			output_item.text = "- %s x%d" % [resource.resource_key, resource.quantity]
			output_container.add_child(output_item)
	
	# Add craft button if craftable
	if _is_craftable(input_data):
		var craft_button = Button.new()
		craft_button.text = "Craft"
		craft_button.custom_minimum_size = Vector2(100, 40)
		craft_button.size_flags_horizontal = SIZE_SHRINK_CENTER
		craft_button.pressed.connect(_on_craft_pressed.bind(input_key))
		output_panel.add_child(craft_button)

func _get_player_resource_quantity(resource_key: String) -> int:
	for item in player_inventory.items:
		if item.resource_id == resource_key:
			return item.quantity
	return 0

func _clear_output_panel():
	# Clear all children except the title
	for i in range(1, output_panel.get_child_count()):
		output_panel.get_child(i).queue_free()

func _on_craft_pressed(input_key: String):
	print("Crafting: ", input_key)
	# Implement actual crafting here
	# 1. Remove resources from player inventory
	# 2. Trigger crafting process
	# 3. Update UI

func _on_filter_toggled(button_pressed: bool):
	# Repopulate the input list based on the filter
	if "workstation_properties" in workstation_data and "input" in workstation_data.workstation_properties:
		# Clear existing inputs
		for child in inputs_list.get_children():
			child.queue_free()
			
		# Repopulate based on new filter setting
		_populate_input_list(workstation_data.workstation_properties.input, button_pressed)

func show_ui():
	is_visible = true
	visible = true
	# Use this if you need to handle pausing the game or disabling other UI elements
	GlobalBuilding.set_ui_interaction(true)

func _on_close_button_pressed():
	is_visible = false
	visible = false
	GlobalBuilding.set_ui_interaction(false)
	
