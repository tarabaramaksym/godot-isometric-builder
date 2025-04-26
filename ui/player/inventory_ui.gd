class_name PlayerInventoryUI extends Control

var inventory: Inventory
var item_container: VBoxContainer

func _ready():
	# Get player inventory reference
	inventory = GlobalPlayer.player.inventory
	
	# Create main container
	item_container = VBoxContainer.new()
	item_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(item_container)
	
	# Set up mouse enter/exit detection for the entire UI
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Add title
	var title = Label.new()
	title.text = "Inventory"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	item_container.add_child(title)
	
	# Connect to inventory changed signal
	inventory.inventory_changed.connect(_on_inventory_changed)
	
	# Initial population of inventory items
	refresh_inventory_display()

func refresh_inventory_display():
	# Clear existing items (except title)
	for i in range(1, item_container.get_child_count()):
		item_container.get_child(i).queue_free()
	
	# Add items from inventory
	for item in inventory.items:
		add_item_entry(item)

func add_item_entry(item):
	var button = Button.new()
	button.text = "%s - %d" % [item.resource_name, item.quantity]
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 40)
	
	# Optional: Connect to button press if you want to do something when clicking an item
	button.pressed.connect(_on_item_button_pressed.bind(item))
	
	# Add mouse enter/exit detection to each button
	button.mouse_entered.connect(_on_mouse_entered)
	button.mouse_exited.connect(_on_mouse_exited)
	
	item_container.add_child(button)

func _on_item_button_pressed(item):
	print("Selected item: ", item.resource_name)
	# Add your item selection logic here
	# For example: GlobalPlayer.selected_item = item.resource_id

func _on_inventory_changed():
	# Refresh the display when inventory changes
	refresh_inventory_display()

func _on_mouse_entered():
	GlobalBuilding.set_ui_interaction(true)

func _on_mouse_exited():
	GlobalBuilding.set_ui_interaction(false)


