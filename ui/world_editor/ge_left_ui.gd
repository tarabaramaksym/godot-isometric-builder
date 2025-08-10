extends ScrollContainer

@export var main_container: VBoxContainer

func _ready():
	var object_data = GlobalDataManager.get_game_object_data()

	var category_containers = {}

	for object_key in object_data.keys():
		var object_data_item = object_data[object_key]
		var object_name = object_data_item["name"]
		var object_category = object_data_item["object_category"]
		
		if !category_containers.has(object_category):
			var category_container = VBoxContainer.new()

			var category_label = Label.new()
			category_label.text = object_category
			category_container.add_child(category_label)

			var button_container = HFlowContainer.new()
			category_container.add_child(button_container)

			category_containers[object_category] = button_container
			main_container.add_child(category_container)

		var button = create_button(object_name, object_data_item.get("icon", ""), 64, 64)
		category_containers[object_category].add_child(button)
		
	
func create_button(object_name: String, icon_path: String, width: int, height: int) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(width, height)
	button.expand_icon = true

	if icon_path:
		button.icon = load(icon_path)
	else:
		button.text = object_name

	button.mouse_entered.connect(func(): set_ui_interaction(true))
	button.mouse_exited.connect(func(): set_ui_interaction(false))
	button.pressed.connect(func():
		GlobalBuilding.set_selected_component(object_name)
	)
	# Set size flags for proper centering in layout
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# Remove all background styling and borders
	var style = StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("disabled", style)
	button.add_theme_stylebox_override("focus", style)
	
	return button

func set_ui_interaction(value: bool):
	GlobalBuilding.set_ui_interaction(value)
