extends Node

var top_left_ui_container: Control
var top_center_ui_container: Control
var top_right_ui_container: Control
var bottom_left_ui_container: Control
var bottom_right_ui_container: Control
var bottom_center_ui_container: Control
var ui_initialized = false

func _ready():
	# We'll use call_deferred to ensure the scene tree is fully loaded
	call_deferred("initialize_ui_references")

func initialize_ui_references():
	# Get the root viewport
	var root = get_tree().get_root()
	
	# Find the Main node
	var main_node = root.get_node_or_null("Main")
	
	if main_node:
		# Find the UI containers within Main
		top_left_ui_container = main_node.get_node_or_null("TopLeftUi")
		bottom_center_ui_container = main_node.get_node_or_null("BottomCenterUi")
		
		if top_left_ui_container and bottom_center_ui_container:
			ui_initialized = true
			print("UI containers found successfully")
		else:
			print("Some UI containers not found. Top Left: ", top_left_ui_container != null, 
				  ", Bottom Center: ", bottom_center_ui_container != null)
	else:
		print("Main node not found in scene tree")
		# Try again after a short delay
		await get_tree().create_timer(0.5).timeout
		initialize_ui_references()

func toggle_ui_visibility(ui_name: String):
	if !ui_initialized:
		initialize_ui_references()

	match ui_name:
		"top_left":
			top_left_ui_container.visible = !top_left_ui_container.visible
		"top_center":
			top_center_ui_container.visible = !top_center_ui_container.visible
		"top_right":
			top_right_ui_container.visible = !top_right_ui_container.visible
		"bottom_left":
			bottom_left_ui_container.visible = !bottom_left_ui_container.visible
		"bottom_center":
			bottom_center_ui_container.visible = !bottom_center_ui_container.visible
		"bottom_right":
			bottom_right_ui_container.visible = !bottom_right_ui_container.visible
		_:
			print("Invalid UI name: ", ui_name)