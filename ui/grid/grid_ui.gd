class_name GridUI extends Control

@export var grid_size: Vector2i = Vector2i(32, 32)

# Dictionary to store grid node positions
# Key: node_id (String), Value: Vector2i grid position
var grid_positions: Dictionary = {}
var grid_nodes: Dictionary = {} # Key: node_id, Value: GridNodeUI instance

func _ready() -> void:
	# Add to group for easy finding
	add_to_group("grid_ui")
	
	# Connect to the GlobalWorkersGrid signal if available
	if GlobalWorkersGrid.has_method("connect"):
		GlobalWorkersGrid.worker_grid_active_changed.connect(_on_worker_grid_active_changed)
	
	# Debug
	print("GridUI ready: " + name)

func _draw():
	# Draw grid lines for visualization
	if GlobalWorkersGrid.is_worker_grid_active:
		var cols = int(size.x / grid_size.x) + 1
		var rows = int(size.y / grid_size.y) + 1
		
		var grid_color = Color(0.5, 0.5, 0.5, 0.3)
		
		for i in range(cols + 1):
			var x = i * grid_size.x
			draw_line(Vector2(x, 0), Vector2(x, size.y), grid_color, 1.0)
		
		for j in range(rows + 1):
			var y = j * grid_size.y
			draw_line(Vector2(0, y), Vector2(size.x, y), grid_color, 1.0)

# Convert global position to grid position
func global_to_grid_position(global_pos: Vector2) -> Vector2i:
	var local_pos = global_pos - global_position
	var grid_pos = Vector2i(
		int(local_pos.x / grid_size.x),
		int(local_pos.y / grid_size.y)
	)
	return grid_pos

# Convert grid position to local position
func grid_to_local_position(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * grid_size.x + grid_size.x / 2,
		grid_pos.y * grid_size.y + grid_size.y / 2
	)

# Place a node on the grid (using the node's instance ID as the grid node ID)
func place_node(draggable_node: Draggable, node: Node, drop_position: Vector2, is_unique: bool = true) -> void:
	print("Placing node in grid: " + node.name + " (is_unique=" + str(is_unique) + ")")
	
	# Generate a unique ID for the node
	var node_id = str(node.get_instance_id())
	
	# Call the shared implementation
	_place_node_impl(draggable_node, node, drop_position, node_id, is_unique)

# Place a node with a custom ID (for non-unique nodes)
func place_node_with_id(draggable_node: Draggable, node: Node, drop_position: Vector2, custom_id: String) -> void:
	print("Placing node with custom ID: " + node.name + " (ID=" + custom_id + ")")
	
	# Call the shared implementation with is_unique=false
	_place_node_impl(draggable_node, node, drop_position, custom_id, false)

# Shared implementation for place_node and place_node_with_id
func _place_node_impl(draggable_node: Draggable, node: Node, drop_position: Vector2, node_id: String, is_unique: bool) -> void:
	# Convert drop position to grid position
	var grid_pos = global_to_grid_position(drop_position)
	print("Grid position: " + str(grid_pos))
	
	# Check if this node is already in the grid
	if is_unique and grid_nodes.has(node_id):
		# Update the position of the existing grid node
		var existing_node = grid_nodes[node_id]
		existing_node.position = grid_to_local_position(grid_pos) - existing_node.size / 2
		grid_positions[node_id] = grid_pos
		print("Updated existing grid node position")
		return
	
	# Create a new GridNodeUI instance directly
	var grid_node_ui = GridNodeUI.new()
	
	# Set up the grid node UI
	grid_node_ui.node_id = node_id
	grid_node_ui.original_node = node  # Reference to original node
	grid_node_ui.draggable_reference = draggable_node
	grid_node_ui.node_name = node.name
	grid_node_ui.original_parent = node.get_parent()

	
	# Check for input/output capabilities from the draggable component
	if node.get_parent() and node.get_parent() is Draggable:
		var draggable = node.get_parent() as Draggable
		grid_node_ui.has_input = draggable.has_input
		grid_node_ui.has_output = draggable.has_output
		print("Node has input: " + str(grid_node_ui.has_input) + ", output: " + str(grid_node_ui.has_output))
	
	# Store grid position
	grid_positions[node_id] = grid_pos
	grid_nodes[node_id] = grid_node_ui
	
	# Add the grid node UI to the grid
	add_child(grid_node_ui)
	
	# Position the grid node UI
	grid_node_ui.position = grid_to_local_position(grid_pos) - grid_node_ui.size / 2
	
	print("Created new grid node: " + grid_node_ui.node_name + " at " + str(grid_pos) + " with ID: " + node_id)

func remove_node(node_id: String) -> void:
	if grid_nodes.has(node_id):
		var grid_node_ui = grid_nodes[node_id]
		
		# Disconnect all connections when removing
		if grid_node_ui.has_method("disconnect_all"):
			grid_node_ui.disconnect_all()
		
		grid_node_ui.queue_free()
		grid_nodes.erase(node_id)
		grid_positions.erase(node_id)
		print("Removed grid node: " + node_id)

# Find a grid node at a global position, checking for connector areas
func find_node_at_position(global_pos: Vector2) -> GridNodeUI:
	for node_id in grid_nodes:
		var grid_node = grid_nodes[node_id] as GridNodeUI
		
		# First check if position is within a connector
		if grid_node.has_input and _is_point_in_control(grid_node.input_connector, global_pos):
			return grid_node
		elif grid_node.has_output and _is_point_in_control(grid_node.output_connector, global_pos):
			return grid_node
		# Then check if position is within the node itself
		elif _is_point_in_control(grid_node, global_pos):
			return grid_node
	
	return null

# Helper function to check if a point is within a control
func _is_point_in_control(control: Control, point: Vector2) -> bool:
	var global_rect = Rect2(control.global_position, control.size)
	return global_rect.has_point(point)

func get_node_grid_position(node_id: String) -> Vector2i:
	if grid_positions.has(node_id):
		return grid_positions[node_id]
	return Vector2i(-1, -1)

func _on_worker_grid_active_changed(active: bool) -> void:
	# Toggle visibility of the grid
	visible = active
	print("GridUI visibility changed to: " + str(active))
	if active:
		queue_redraw()  # Redraw the grid lines

