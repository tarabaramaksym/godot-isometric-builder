extends Control

var building_builder: BuildingBuilder
var size_options_container: VBoxContainer
var axis_containers = {}

func _ready():
    # Get reference to building builder
    building_builder = get_node("/root/Main/BuildingBuilder")  # Adjust path as needed
    
    if building_builder:
        building_builder.connect("size_options_changed", _on_size_options_changed)
    
    # Create main container
    size_options_container = VBoxContainer.new()
    size_options_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    add_child(size_options_container)
    
    # Add mouse enter/exit detection for the entire UI
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)
    
    # Add title
    var title = Label.new()
    title.text = "Size Options"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 16)
    size_options_container.add_child(title)

func _on_size_options_changed(options):
    # Clear existing options
    for child in size_options_container.get_children():
        if child.get_index() > 0:  # Skip the title
            child.queue_free()
    
    axis_containers.clear()
    
    # If no options, hide or show message
    if options.is_empty():
        return
    
    # Add UI elements for each axis option
    for axis in options.keys():
        var axis_data = options[axis]
        
        # Create container for this axis
        var axis_container = VBoxContainer.new()
        axis_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        size_options_container.add_child(axis_container)
        axis_containers[axis] = axis_container
        
        # Add axis label
        var label = Label.new()
        label.text = axis.to_upper() + " Size"
        axis_container.add_child(label)
        
        # Add size buttons container
        var buttons_container = HBoxContainer.new()
        buttons_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        axis_container.add_child(buttons_container)
        
        # Add buttons for each size option
        for size_value in range(axis_data.min, axis_data.max + 1):
            var button = Button.new()
            button.text = str(size_value)
            button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            button.pressed.connect(_on_size_button_pressed.bind(axis, size_value))
            
            # Add mouse enter/exit events to each button
            button.mouse_entered.connect(_on_mouse_entered)
            button.mouse_exited.connect(_on_mouse_exited)
            
            buttons_container.add_child(button)

func _on_size_button_pressed(axis, value):
    if building_builder:
        building_builder.set_size_value(axis, value)
        print("Set ", axis, " size to ", value)

func _on_mouse_entered():
    GlobalBuilding.ui_interaction = true

func _on_mouse_exited():
    GlobalBuilding.ui_interaction = false 