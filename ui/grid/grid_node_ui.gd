class_name GridNodeUI extends Control

# Reference to the original node
var original_node: Node
var draggable_reference: Draggable
var original_parent: Node
var node_id: String = ""
var node_name: String = "Unknown"

# Connection properties
var has_input: bool = false
var has_output: bool = false
var input_connector: Control
var output_connector: Control
var connections: Array = [] # Array of [from_node, to_node] connections

# UI elements
var label: Label
var panel: Panel
var drag_active: bool = false
var drag_offset: Vector2 = Vector2.ZERO

# Line drawing for active connection
var drawing_connection: bool = false
var connection_start: Vector2
var connection_end: Vector2
var connection_from_output: bool = false # True if dragging from output, false if from input

# Connection signals
signal connection_started(node: GridNodeUI, is_output: bool, start_pos: Vector2)
signal connection_ended(node: GridNodeUI, is_output: bool, end_pos: Vector2)

func _ready() -> void:
    # Set up minimum size
    custom_minimum_size = Vector2(30, 30)
    size = Vector2(grid_size().x - 4, grid_size().y - 4)  # Slightly smaller than grid cell
    
    # Create a background panel
    panel = Panel.new()
    panel.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(panel)
    
    # Create a label for the node name
    label = Label.new()
    label.set_anchors_preset(Control.PRESET_FULL_RECT)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.text = node_name
    label.clip_text = true
    add_child(label)
    
    # Check if the original node has input/output capabilities
    _setup_connectors()
    
    # Add dragging functionality
    set_process_input(true)
    
    print("GridNodeUI ready: " + node_name)

func _setup_connectors() -> void:
    # Get has_input/has_output from the original Draggable component
    if original_node and original_node.get_parent() and original_node.get_parent().has_method("get_script"):
        var draggable = draggable_reference
        if draggable:
            has_input = draggable.has_input
            has_output = draggable.has_output
    
    # Create input connector if needed
    if has_input:
        input_connector = _create_connector(Color(0.2, 0.7, 0.9, 1.0))
        input_connector.position = Vector2(-input_connector.size.x / 2, size.y / 2 - input_connector.size.y / 2)
        add_child(input_connector)
    
    # Create output connector if needed
    if has_output:
        output_connector = _create_connector(Color(0.9, 0.5, 0.2, 1.0))
        output_connector.position = Vector2(size.x - output_connector.size.x / 2, size.y / 2 - output_connector.size.y / 2)
        add_child(output_connector)

func _create_connector(color: Color) -> Control:
    var connector = Control.new()
    connector.custom_minimum_size = Vector2(10, 10)
    connector.size = Vector2(10, 10)
    
    var connector_panel = Panel.new()
    connector_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
    connector_panel.self_modulate = color
    connector.add_child(connector_panel)

    print('create connector')
    
    return connector

func _draw() -> void:
    # Draw active connection line if we're connecting
    if drawing_connection:
        var control_offset = 80  # Control point offset for the bezier curve
        var start = connection_start - global_position
        var end = connection_end - global_position
        
        # Calculate control points for bezier curve
        var control1 = start + Vector2(control_offset, 0)
        var control2 = end - Vector2(control_offset, 0)
        
        # Draw the bezier curve
        _draw_bezier_connection(start, control1, control2, end, Color(1, 1, 0, 0.8), 2.0)
    
    # Don't draw connections while dragging
    if drag_active:
        return
    
    # Draw existing connections
    for connection in connections:
        if connection.size() >= 2:
            var from_node = connection[0]
            var to_node = connection[1]
            
            if from_node is GridNodeUI and to_node is GridNodeUI:
                # Calculate the connection points
                if from_node == self and has_output and to_node.has_input:
                    _draw_connection_to(to_node)
                elif to_node == self and has_input and from_node.has_output:
                    # Connection is drawn by the output node
                    pass

# Draw a connection from this node to another node
func _draw_connection_to(to_node: GridNodeUI) -> void:
    if not has_output or not to_node.has_input or drag_active or to_node.drag_active:
        return
    
    # Get start and end positions
    var start = output_connector.position + output_connector.size / 2
    
    # Convert the target node's input connector position to our local coordinates
    var global_target = to_node.global_position + to_node.input_connector.position + to_node.input_connector.size / 2
    var end = global_target - global_position
    
    # Calculate control points for bezier curve
    var distance = start.distance_to(end)
    var control_offset = min(80, distance * 0.5)  # Scale control points based on distance
    
    var control1 = start + Vector2(control_offset, 0)
    var control2 = end - Vector2(control_offset, 0)
    
    # Draw the bezier curve
    _draw_bezier_connection(start, control1, control2, end, Color(0.8, 0.6, 0.0, 0.7), 2.0)

# Draw a bezier curve between two points
func _draw_bezier_connection(start: Vector2, control1: Vector2, control2: Vector2, end: Vector2, color: Color, width: float) -> void:
    var points = PackedVector2Array()
    var segments = 20  # Number of segments for the curve
    
    # Generate points along the bezier curve
    for i in range(segments + 1):
        var t = float(i) / segments
        var point = _cubic_bezier(start, control1, control2, end, t)
        points.append(point)
    
    # Draw the curve as a polyline
    if points.size() > 1:
        draw_polyline(points, color, width, true)  # true for antialiasing

# Calculate a point on a cubic bezier curve at time t
func _cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
    var q0 = p0.lerp(p1, t)
    var q1 = p1.lerp(p2, t)
    var q2 = p2.lerp(p3, t)
    
    var r0 = q0.lerp(q1, t)
    var r1 = q1.lerp(q2, t)
    
    var s = r0.lerp(r1, t)
    return s

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        var mouse_event = event as InputEventMouseButton
        if mouse_event.button_index == MOUSE_BUTTON_LEFT:
            if mouse_event.pressed:
                # Check for connector clicks first
                if has_input and _is_point_in_control(input_connector, mouse_event.global_position):
                    _start_connection(mouse_event.global_position, false)
                elif has_output and _is_point_in_control(output_connector, mouse_event.global_position):
                    _start_connection(mouse_event.global_position, true)
                # Otherwise check if click is within this control for dragging
                elif get_global_rect().has_point(mouse_event.global_position):
                    _on_drag_start(mouse_event.global_position)
            elif drag_active:
                _on_drag_end(mouse_event.global_position)
            elif drawing_connection:
                _end_connection(mouse_event.global_position)
    
    # Handle movement during drag
    if drag_active and event is InputEventMouseMotion:
        var motion_event = event as InputEventMouseMotion
        global_position = motion_event.global_position - drag_offset
        
        # Force redraw of all connected nodes to update connection lines
        _update_all_connected_nodes()
    
    # Handle connection line drawing
    if drawing_connection and event is InputEventMouseMotion:
        var motion_event = event as InputEventMouseMotion
        connection_end = motion_event.global_position
        queue_redraw()

# Update all nodes that have connections with this node
func _update_all_connected_nodes() -> void:
    var nodes_to_update = []
    
    # Find all connected nodes
    for connection in connections:
        if connection.size() >= 2:
            var from_node = connection[0]
            var to_node = connection[1]
            
            if from_node != self and not nodes_to_update.has(from_node):
                nodes_to_update.append(from_node)
            
            if to_node != self and not nodes_to_update.has(to_node):
                nodes_to_update.append(to_node)
    
    # Force redraw of all connected nodes
    for node in nodes_to_update:
        if is_instance_valid(node):
            node.queue_redraw()
    
    # Also redraw ourselves
    queue_redraw()

func _start_connection(start_pos: Vector2, is_output: bool) -> void:
    print("Starting connection from " + ("output" if is_output else "input") + " of " + node_name)
    drawing_connection = true
    connection_from_output = is_output
    
    # Set start point based on connector
    if is_output:
        connection_start = output_connector.global_position + output_connector.size / 2
    else:
        connection_start = input_connector.global_position + input_connector.size / 2
    
    connection_end = start_pos
    
    # Emit signal
    connection_started.emit(self, is_output, start_pos)
    
    # Force redraw
    queue_redraw()

func _end_connection(end_pos: Vector2) -> void:
    if drawing_connection:
        print("Ending connection")
        drawing_connection = false
        
        # Find if we're over another grid node's connector
        var grid_ui = get_parent()
        if grid_ui is GridUI:
            var target_node = grid_ui.find_node_at_position(end_pos)
            
            if target_node and target_node != self:
                print("Found target node: " + target_node.node_name)
                
                # Check if we're connecting output to input or input to output
                if connection_from_output and target_node.has_input:
                    _connect_nodes(self, target_node)
                elif not connection_from_output and target_node.has_output:
                    _connect_nodes(target_node, self)
        
        # Emit signal
        connection_ended.emit(self, connection_from_output, end_pos)
        
        # Force redraw
        queue_redraw()

func _connect_nodes(from_node: GridNodeUI, to_node: GridNodeUI) -> void:
    print("Connecting " + from_node.node_name + " to " + to_node.node_name)
    
    # Check if connection already exists
    for connection in connections:
        if connection.size() >= 2 and connection[0] == from_node and connection[1] == to_node:
            print("Connection already exists")
            return
    
    # Add connection to both nodes
    var new_connection = [from_node, to_node]
    from_node.connections.append(new_connection)
    to_node.connections.append(new_connection)
    
    # Force redraw
    from_node.queue_redraw()
    to_node.queue_redraw()

func _on_drag_start(mouse_position: Vector2) -> void:
    print("Starting to drag grid node: " + node_name)
    drag_active = true
    drag_offset = mouse_position - global_position
    # Change appearance to indicate dragging
    panel.modulate = Color(0.8, 0.8, 1.0, 0.8)
    
    # Bring to front
    get_parent().move_child(self, get_parent().get_child_count() - 1)
    
    # Force redraw to hide connections while dragging
    _update_all_connected_nodes()

func _on_drag_end(mouse_position: Vector2) -> void:
    print("Ending drag of grid node: " + node_name)
    drag_active = false
    
    # Return to normal appearance
    panel.modulate = Color(1, 1, 1, 1)
    
    # Check if we should reposition in the grid
    if get_parent() is GridUI:
        var grid_ui = get_parent() as GridUI
        
        # Check if we're still within grid bounds
        if _is_point_in_control(grid_ui, mouse_position):
            var new_grid_pos = grid_ui.global_to_grid_position(mouse_position)
            
            # Update in the grid UI
            grid_ui.grid_positions[node_id] = new_grid_pos
            
            # Update our position
            position = grid_ui.grid_to_local_position(new_grid_pos) - size / 2
            print("Repositioned to " + str(new_grid_pos))
        else:
            # Remove from grid if dragged outside
            print("Removing node from grid - dragged outside")
            grid_ui.remove_node(node_id)
    
    # Force redraw to show connections again
    _update_all_connected_nodes()

func _is_point_in_control(control: Control, point: Vector2) -> bool:
    var rect = Rect2(control.global_position, control.size)
    return rect.has_point(point)

# Get the grid size from parent GridUI
func grid_size() -> Vector2:
    if get_parent() is GridUI:
        return Vector2(get_parent().grid_size)
    return Vector2(32, 32)  # Default

# Update the display when the node name changes
func set_node_name(new_name: String) -> void:
    node_name = new_name
    if label:
        label.text = node_name

# Disconnect a specific connection
func disconnect_from(other_node: GridNodeUI) -> void:
    var to_remove = []
    
    for i in range(connections.size()):
        var connection = connections[i]
        if connection.size() >= 2:
            if (connection[0] == self and connection[1] == other_node) or \
               (connection[0] == other_node and connection[1] == self):
                to_remove.append(i)
    
    # Remove connections in reverse order to avoid index issues
    for i in range(to_remove.size() - 1, -1, -1):
        connections.remove_at(to_remove[i])
    
    # Force redraw
    queue_redraw()
    other_node.queue_redraw()

# Disconnect all connections when removed
func disconnect_all() -> void:
    var nodes_to_update = []
    
    for connection in connections:
        if connection.size() >= 2:
            if connection[0] != self and not nodes_to_update.has(connection[0]):
                nodes_to_update.append(connection[0])
            if connection[1] != self and not nodes_to_update.has(connection[1]):
                nodes_to_update.append(connection[1])
    
    # Clear connections
    connections.clear()
    
    # Update other nodes
    for node in nodes_to_update:
        if is_instance_valid(node):
            node.disconnect_from(self)
            node.queue_redraw()
    
    # Force redraw
    queue_redraw()
