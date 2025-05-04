class_name Draggable extends Node

signal drag_started(node: Node)
signal drag_ended(node: Node)

@export var is_unique: bool = false
@export var has_input: bool = false
@export var has_output: bool = false

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_parent: Node
var original_position: Vector3
var dragged_node: Node
var parent_node: Node  # Store reference to parent node
var temp_clone: Node  # Temporary clone for dragging

func _ready() -> void:
    if GlobalWorkersGrid.has_method("connect"):
        GlobalWorkersGrid.worker_grid_active_changed.connect(_on_worker_grid_active_changed)

    # Get the parent node which we'll drag
    parent_node = get_parent()
    
    # For debugging purposes
    print("Draggable attached to: " + parent_node.name)
    print("Is unique: " + str(is_unique))
    print("Has input: " + str(has_input) + ", has output: " + str(has_output))
    
    # Turn on input processing
    set_process_input(true)
    
    #mp test
    GlobalWorkersGrid.set_worker_grid_active(true)
    print("Worker grid active: " + str(GlobalWorkersGrid.is_worker_grid_active))

func _process(_delta: float) -> void:
    if is_dragging and temp_clone and GlobalWorkersGrid.is_worker_grid_active:
        print('dragging: ' + parent_node.name)
        # Get mouse position in viewport
        var mouse_pos = get_viewport().get_mouse_position()
        
        # Move the temp clone to follow the mouse
        if temp_clone is Control:
            temp_clone.global_position = mouse_pos - drag_offset
        elif temp_clone is Node3D:
            # For 3D objects, project the mouse position to the 3D world
            var camera = get_viewport().get_camera_3d()
            if camera:
                var from = camera.project_ray_origin(mouse_pos)
                var to = from + camera.project_ray_normal(mouse_pos) * 1000
                var space_state = camera.get_world_3d().direct_space_state
                var query = PhysicsRayQueryParameters3D.create(from, to)
                var result = space_state.intersect_ray(query)
                if result:
                    temp_clone.global_position = result.position

func _input(event: InputEvent) -> void:
    # Handle starting the drag
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            # Check if click is on our parent (for 2D)
            if parent_node is Control:
                var rect = Rect2(parent_node.global_position, parent_node.size)
                if rect.has_point(event.global_position):
                    print("Starting drag on Control: " + parent_node.name)
                    start_drag(parent_node)
            # For 3D objects, use raycast
            elif parent_node is Node3D:
                var camera = get_viewport().get_camera_3d()
                if camera:
                    var from = camera.project_ray_origin(event.position)
                    var to = from + camera.project_ray_normal(event.position) * 1000
                    var space_state = camera.get_world_3d().direct_space_state
                    var query = PhysicsRayQueryParameters3D.create(from, to)
                    var result = space_state.intersect_ray(query)
                    if result and result.collider == parent_node:
                        print("Starting drag on 3D node: " + parent_node.name)
                        start_drag(parent_node)
        elif is_dragging:
            # Mouse released while dragging
            print("Ending drag")
            end_drag()

func create_clone(node: Node) -> Node:
    var clone: Node
    
    # For Control nodes, create a simplified clone
    if node is Control:
        clone = Control.new()
        clone.size = node.size
        clone.position = node.position
        clone.global_position = node.global_position
        
        # Add a visual representation (panel)
        var panel = Panel.new()
        panel.set_anchors_preset(Control.PRESET_FULL_RECT)
        clone.add_child(panel)
        
        # Add a label with the node name
        var label = Label.new()
        label.text = node.name
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        label.set_anchors_preset(Control.PRESET_FULL_RECT)
        clone.add_child(label)
        
        # Add input/output indicators if needed
        if has_input or has_output:
            if has_input:
                var input_indicator = Panel.new()
                input_indicator.size = Vector2(10, 10)
                input_indicator.position = Vector2(-5, clone.size.y / 2 - 5)
                input_indicator.self_modulate = Color(0.2, 0.7, 0.9, 1.0)
                clone.add_child(input_indicator)
            
            if has_output:
                var output_indicator = Panel.new()
                output_indicator.size = Vector2(10, 10)
                output_indicator.position = Vector2(clone.size.x - 5, clone.size.y / 2 - 5)
                output_indicator.self_modulate = Color(0.9, 0.5, 0.2, 1.0)
                clone.add_child(output_indicator)
    
    # For 3D nodes, create a simplified placeholder
    elif node is Node3D:
        clone = Node3D.new()
        clone.global_position = node.global_position
        clone.global_rotation = node.global_rotation
        
        # Create a simple visual representation (mesh)
        var mesh_instance = MeshInstance3D.new()
        var box_mesh = BoxMesh.new()
        
        # Try to estimate size from the original object
        if node is MeshInstance3D and node.mesh:
            var aabb = node.mesh.get_aabb()
            box_mesh.size = aabb.size
        else:
            box_mesh.size = Vector3(1, 1, 1)
            
        mesh_instance.mesh = box_mesh
        clone.add_child(mesh_instance)
        
        # Add input/output indicators for 3D objects if needed
        # Would need more complex implementation for 3D connectors
    
    return clone

func start_drag(node: Node) -> void:
    if not GlobalWorkersGrid.is_worker_grid_active:
        print("Worker grid not active, can't drag")
        return
        
    print('Start drag on: ' + node.name)
    is_dragging = true
    dragged_node = node
    original_parent = node.get_parent()
    
    if node is Control:
        original_position = Vector3(node.position.x, node.position.y, 0)
    elif node is Node3D:
        original_position = node.global_position
    
    # Create a temporary clone for dragging
    temp_clone = create_clone(node)
    
    # Add the clone to the scene
    get_tree().root.add_child(temp_clone)
    
    # Set up drag offset for controls
    if temp_clone is Control:
        drag_offset = get_viewport().get_mouse_position() - temp_clone.global_position
    
    drag_started.emit(node)

func end_drag() -> void:
    if is_dragging and dragged_node and temp_clone:
        is_dragging = false
        
        # Find the GridUI to drop onto
        var grid_ui = _find_grid_ui()
        
        if grid_ui and GlobalWorkersGrid.is_worker_grid_active:
            print("Dropping on grid: " + grid_ui.name + " (is_unique=" + str(is_unique) + ")")
            _drop_on_grid(grid_ui)
        else:
            print("Not dropping on grid, removing clone")
        
        # Remove the temporary clone
        if temp_clone:
            temp_clone.queue_free()
            temp_clone = null
        
        drag_ended.emit(dragged_node)
        dragged_node = null

func _find_grid_ui() -> GridUI:
    # Find all GridUI nodes in the scene
    var grid_uis = get_tree().get_nodes_in_group("grid_ui")
    print("Found " + str(grid_uis.size()) + " grid UIs")
    
    if grid_uis.size() > 0:
        var mouse_pos = get_viewport().get_mouse_position()
        
        # Check if mouse is over any GridUI
        for grid_ui in grid_uis:
            if grid_ui is GridUI:
                if _is_point_in_control(grid_ui, mouse_pos):
                    return grid_ui
    
    return null

func _is_point_in_control(control: Control, point: Vector2) -> bool:
    var rect = Rect2(control.global_position, control.size)
    return rect.has_point(point)

func _drop_on_grid(grid_ui: GridUI) -> void:
    # If is_unique is true, we'll update the existing node if it exists
    # If is_unique is false, we'll create a new node even if one already exists
    var mouse_pos = get_viewport().get_mouse_position()
    
    if is_unique:
        # Let the GridUI handle the placement using the original node reference
        grid_ui.place_node(self, dragged_node, mouse_pos, is_unique)
    else:
        # For non-unique, generate a new node ID to force creating a new entry
        var unique_node_id = str(randi()) + "_" + str(Time.get_ticks_msec())
        grid_ui.place_node_with_id(self, dragged_node, mouse_pos, unique_node_id)

func _on_worker_grid_active_changed(active: bool) -> void:
    print("Worker grid active changed: " + str(active))
    
    if not active and is_dragging:
        # Cancel dragging if grid is deactivated
        is_dragging = false
        
        # Remove temporary clone
        if temp_clone:
            temp_clone.queue_free()
            temp_clone = null
        
        drag_ended.emit(dragged_node)
        dragged_node = null
