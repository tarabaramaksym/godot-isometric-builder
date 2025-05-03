extends Control

@export var ui_config_path: String
@export_enum("Horizontal", "Vertical") var type: int
@export var position_center: bool = false
@export var preselect_first_tab: bool = false
@export var icons_size: int = 64

var ui_data: Dictionary
var navigation_stack: Array = []
var tab_containers: Array = []

func _ready():
    load_ui_config()
    setup_ui()

func initialize_container():
    var container
    if type == 0:
        container = HBoxContainer.new()
    else:
        container = VBoxContainer.new()
        
    # Always set alignment to center for consistent layout
    container.alignment = BoxContainer.ALIGNMENT_CENTER
    return container

func setup_ui():
    # Clear any existing UI
    for child in get_children():
        child.queue_free()

    # Wrapper for centering if needed
    var wrapper = null
    if position_center:
        wrapper = CenterContainer.new()
        wrapper.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
        wrapper.size_flags_horizontal = Control.SIZE_FILL
        add_child(wrapper)
    
    # Create main vertical layout
    var main_layout = VBoxContainer.new()
    main_layout.alignment = BoxContainer.ALIGNMENT_CENTER
    
    if position_center:
        # When using center container, we use simpler setup
        wrapper.add_child(main_layout)
    else:
        main_layout.set_anchors_preset(Control.PRESET_FULL_RECT)
        add_child(main_layout)
    
    # Create root tab buttons
    var root_tabs = initialize_container()
    main_layout.add_child(root_tabs)
    
    # Create initial container for first level of content
    var content_container = initialize_container()
    main_layout.add_child(content_container)
    tab_containers.append(content_container)
    
    # Add root level tab buttons
    var first_key = null
    for key in ui_data.keys():
        if first_key == null:
            first_key = key
        var tab_data = ui_data[key]
        var tab_button = create_button(tab_data.icon, icons_size, icons_size)
        tab_button.pressed.connect(func(): navigate_to([key]))
        root_tabs.add_child(tab_button)
    
    # Set initial view to empty
    clear_all_containers()
    
    # Auto-select first tab if enabled
    if preselect_first_tab and first_key != null:
        navigate_to([first_key])
    
    # Schedule a deferred recalculation of layout
    if position_center:
        call_deferred("_recalculate_layout", wrapper)
    else:
        call_deferred("_recalculate_layout", main_layout)

# Called after all UI elements are added to force layout recalculation
func _recalculate_layout(main_layout):
    # Force a layout recalculation
    main_layout.reset_size()
    
    # Also ensure the parent control (the UI container itself) is properly refreshed
    reset_size()
    size = size  # Trick to force minimum size recalculation
    
    # Ensure proper centering by setting position explicitly if needed
    if position_center:
        # Make sure main_layout is centered horizontally
        main_layout.position.x = (size.x - main_layout.size.x) / 2

func navigate_to(path: Array):
    # If clicking on a root tab, clear everything first
    if path.size() == 1:
        clear_all_containers()
    else:
        # If clicking on a subtab, only clear containers deeper than the current level
        var level = path.size() - 1
        clear_containers_from_level(level)
    
    # Set the new navigation path
    navigation_stack = path
    
    # Navigate to the current path
    update_content()

func update_content():
    # Get the data at the current navigation path
    var current_data = get_data_at_path(navigation_stack)
    
    if current_data == null:
        return
    
    if current_data.type == "tab":
        display_tab_content(current_data.items, navigation_stack.size() - 1)
    elif current_data.type == "action":
        handle_action(current_data)
    elif current_data.type == "building":
        switch_to_item(current_data.building_key)

func display_tab_content(items: Dictionary, container_index: int):
    # Ensure we have enough containers
    ensure_container_count(container_index + 1)
    
    # Get the container for this level
    var container = tab_containers[container_index]
    
    # Clear the container
    for child in container.get_children():
        child.queue_free()
    
    # Add items to the container
    for key in items.keys():
        var item_data = items[key]
        var button = create_button(item_data.icon, icons_size, icons_size)
        
        if item_data.type == "tab":
            # For tabs, add navigation
            var new_path = navigation_stack.duplicate()
            new_path.append(key)
            button.pressed.connect(func(): navigate_to(new_path))
        elif item_data.type == "building":
            # For buildings, switch to item
            button.pressed.connect(func(): switch_to_item(item_data.building_key))
        elif item_data.type == "action":
            handle_action(item_data.action)

        container.add_child(button)

func handle_action(item_data: Dictionary):
    match item_data.action:
        "toggle_ui":
            GlobalUiManager.toggle_ui_visibility(item_data.toggle_ui)

func ensure_container_count(count: int):
    # Make sure we have enough containers for the current depth
    while tab_containers.size() < count:
        var container = initialize_container()
        
        # Center the container's content
        if type == 0:  # Horizontal container
            container.alignment = BoxContainer.ALIGNMENT_CENTER
        else:  # Vertical container
            container.alignment = BoxContainer.ALIGNMENT_CENTER
        
        # Add the new container next to the last one
        var parent = tab_containers[0].get_parent()
        parent.add_child(container)
        tab_containers.append(container)

func clear_containers_from_level(level: int):
    # Clear containers from the specified level onwards
    for i in range(level, tab_containers.size()):
        for child in tab_containers[i].get_children():
            child.queue_free()

func clear_all_containers():
    # Clear all containers but don't remove them
    for container in tab_containers:
        for child in container.get_children():
            child.queue_free()

func get_data_at_path(path: Array) -> Dictionary:
    var current = ui_data
    
    for i in range(path.size()):
        var key = path[i]
        
        if not current.has(key):
            return {}
            
        current = current[key]
        
        # If we're not at the end of the path, we need to go into the items
        if i < path.size() - 1:
            if current.has("items"):
                current = current.items
            else:
                return {}
    
    return current

func create_button(icon_path: String, width: int, height: int) -> Button:
    var button = Button.new()
    button.custom_minimum_size = Vector2(width, height)
    button.expand_icon = true
    button.icon = load(icon_path)
    button.mouse_entered.connect(func(): set_ui_interaction(true))
    button.mouse_exited.connect(func(): set_ui_interaction(false))
    
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

func switch_to_item(item_key: String):
    GlobalBuilding.set_selected_component(item_key)

func set_ui_interaction(value: bool):
    GlobalBuilding.set_ui_interaction(value)

func load_ui_config() -> Dictionary:
    var file = FileAccess.open(ui_config_path, FileAccess.READ)
    if not file:
        print("Failed to open UI config file")
        return {}
        
    var json_text = file.get_as_text()
    file.close()
    
    var json = JSON.new()
    var error = json.parse(json_text)
    if error == OK:
        ui_data = json.data
        return json.data
    else:
        return {}
