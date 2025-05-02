class_name BuildingMouseHandler extends Node

@export var camera: Camera3D
@export var plane: CSGBox3D
@export var gridmap: GridMap
@export var building_builder: Node

# Drag building state
var is_dragging = false
var drag_start_position = Vector3.ZERO
var drag_current_position = Vector3.ZERO
var drag_previews = []  # Array to store preview instances for dragging

var adjust_y = false
var adjust_y_value = 0

var locked_y_value = 0

func _ready():
    # If BuildingBuilder isn't already in the scene, create it
    if not building_builder:
        building_builder = BuildingBuilder.new()
        add_child(building_builder)

func add_mesh(param_position: Vector3, is_plane: bool):
    building_builder.add_mesh(param_position, gridmap, is_plane)

func has_mesh_at_position(param_position: Vector3) -> bool:
    return building_builder.has_mesh_at_position(param_position, gridmap)

func _process(_delta):
    if Input.is_action_just_pressed("ui_right_click"):
        GlobalBuilding.set_selected_component("")
        return

    # Check for rotation input
    if Input.is_action_just_pressed("rotate") and not GlobalBuilding.ui_interaction:
        building_builder.rotate_component()
    
    if GlobalBuilding.ui_interaction or GlobalBuilding.selected_component.is_empty():
        clear_all_previews()
        return

    # Get mouse ray
    var mouse_pos = get_viewport().get_mouse_position()
    var from = camera.project_ray_origin(mouse_pos)
    var to = from + camera.project_ray_normal(mouse_pos) * 1000
    
    var space_state = camera.get_world_3d().direct_space_state
    var physics = PhysicsRayQueryParameters3D.new()
    physics.from = from
    physics.to = to
    
    var result = space_state.intersect_ray(physics)
    
    # Handle dragging and placement
    if result and (result.collider == plane or result.collider is StaticBody3D):
        var is_top_face = result.collider is StaticBody3D and result.normal.dot(Vector3.UP) > 0.99

        var is_plane = result.collider == plane
        var world_pos = result.position
        var cell = gridmap.local_to_map(world_pos)
        var cell_world_pos = gridmap.map_to_local(cell)

        if !is_top_face:
            adjust_y = false

        if (cell_world_pos.y != world_pos.y or cell.y != world_pos.y) and is_top_face:
            cell_world_pos.y = world_pos.y
            adjust_y = true
            adjust_y_value = world_pos.y
        
        # Get component sizing type
        var sizing_type = get_component_sizing_type()
        
        # Start dragging on left click (if component allows dragging)
        if Input.is_action_just_pressed("ui_left_click") and not is_dragging and not GlobalBuilding.selected_component.is_empty():
            if sizing_type != "single":
                is_dragging = true
                locked_y_value = cell_world_pos.y
                drag_start_position = cell_world_pos
                drag_current_position = cell_world_pos
                update_drag_previews()
            else:
                # For single placement, just place directly
                add_mesh(cell_world_pos, is_plane)
                building_builder.navigation_region.bake_navigation_mesh()
        
        # Update drag position while dragging
        if is_dragging:
            drag_current_position = cell_world_pos
            update_drag_previews()
        
        # End dragging and place objects
        if Input.is_action_just_released("ui_left_click") and is_dragging:
            place_dragged_components()
            adjust_y = false
            locked_y_value = 0
            is_dragging = false
            clear_all_previews()
        
        # Show regular preview when not dragging
        if not is_dragging and not GlobalBuilding.selected_component.is_empty():
            if not building_builder.has_preview():
                building_builder.update_preview()
            building_builder.update_preview_position(cell_world_pos)
    else:
        # Clear preview when not pointing at valid surface
        if not is_dragging:
            building_builder.clear_preview()
        
        # End drag if released outside valid area
        if Input.is_action_just_released("ui_left_click") and is_dragging:
            is_dragging = false
            adjust_y = false
            locked_y_value = 0
            clear_all_previews()

# Get the sizing type of the current component
func get_component_sizing_type() -> String:
    if GlobalBuilding.selected_component.is_empty():
        return "single"
    
    var component_data = building_builder.building_components.get(GlobalBuilding.selected_component)
    if component_data:
        return component_data.get("sizing_type", "single")
    
    return "single"

# Update preview meshes along the drag line
func update_drag_previews():
    # Clear existing previews
    clear_all_previews()
    
    # Calculate cells in the drag area
    var cells = get_cells_in_drag()
    
    # Create a preview for each cell
    for cell_pos in cells:
        create_drag_preview(cell_pos)

# Get all grid cells between drag start and current position
func get_cells_in_drag() -> Array:
    var cells = []
    
    # Get grid coordinates
    var start_cell = gridmap.local_to_map(drag_start_position)
    var end_cell = gridmap.local_to_map(drag_current_position)
    
    if adjust_y:
        print('adjust_y - ', adjust_y)
        start_cell.y = adjust_y_value
        end_cell.y = adjust_y_value

    if locked_y_value != 0:
        start_cell.y = locked_y_value
        end_cell.y = locked_y_value

    # Get sizing type to determine behavior
    var sizing_type = get_component_sizing_type()
    
    if sizing_type == "directional":
        # Directional: Allow stretching in only one direction (X or Z)
        var diff_x = end_cell.x - start_cell.x
        var diff_z = end_cell.z - start_cell.z
        
        # Determine primary direction (largest difference)
        if abs(diff_x) >= abs(diff_z):
            # X-direction drag
            var x_min = min(start_cell.x, end_cell.x)
            var x_max = max(start_cell.x, end_cell.x)
            
            for x in range(x_min, x_max + 1):
                var cell_pos = gridmap.map_to_local(Vector3i(x, start_cell.y, start_cell.z))

                if adjust_y:
                    cell_pos.y = adjust_y_value
                
                if locked_y_value != 0:
                    cell_pos.y = locked_y_value

                cells.append(cell_pos)
        else:
            # Z-direction drag
            var z_min = min(start_cell.z, end_cell.z)
            var z_max = max(start_cell.z, end_cell.z)
            
            for z in range(z_min, z_max + 1):
                var cell_pos = gridmap.map_to_local(Vector3i(start_cell.x, start_cell.y, z))

                if adjust_y:
                    cell_pos.y = adjust_y_value

                if locked_y_value != 0:
                    cell_pos.y = locked_y_value

                cells.append(cell_pos)
    
    elif sizing_type == "area":
        # Area: Allow stretching in both X and Z directions (2D rectangle)
        var x_min = min(start_cell.x, end_cell.x)
        var x_max = max(start_cell.x, end_cell.x)
        var z_min = min(start_cell.z, end_cell.z)
        var z_max = max(start_cell.z, end_cell.z)
        
        for x in range(x_min, x_max + 1):
            for z in range(z_min, z_max + 1):
                var cell_pos = gridmap.map_to_local(Vector3i(x, start_cell.y, z))

                if adjust_y:
                    cell_pos.y = adjust_y_value

                if locked_y_value != 0:
                    cell_pos.y = locked_y_value

                cells.append(cell_pos)
    
    else: # "single" or default
        # Single: Only place at start position
        cells.append(drag_start_position)
    
    return cells

# Create a single preview at the specified position
func create_drag_preview(param_position: Vector3):
    if GlobalBuilding.selected_component.is_empty():
        return
    
    # Get component data
    var component_data = building_builder.building_components.get(GlobalBuilding.selected_component)
    if not component_data:
        return
    
    # Create preview instance
    var preview = building_builder.create_preview_instance()
    if preview:
        preview.transform.origin = param_position
        
        # Apply the same height adjustment used in regular preview
        if component_data.mesh_type == "simple" and not "position" in component_data:
            # Find mesh instance to get size
            for child in preview.get_children():
                if child is MeshInstance3D and child.mesh is BoxMesh:
                    # Apply the same height offset used in create_simple_mesh
                    preview.transform.origin.y += child.mesh.size.y / 2
                    break
        # For loaded mesh scenes, apply transparency to child meshes
        elif component_data.mesh_type == "load":
            # Add transparency to all mesh instances in the loaded scene
            for child in preview.get_children():
                if child is Node3D:  # The mesh_scene should be a Node3D
                    _apply_transparency_to_mesh_scene(child)
        
        # Add to scene and to our list
        add_child(preview)
        drag_previews.append(preview)

# Helper function to apply transparency to all meshes in a loaded scene
func _apply_transparency_to_mesh_scene(node: Node):
    # Recursively apply transparency to all MeshInstance3D nodes
    if node is MeshInstance3D:
        var material = node.get_surface_override_material(0)
        if not material:
            material = StandardMaterial3D.new()
            node.material_override = material
        
        if material is StandardMaterial3D:
            material.flags_transparent = true
            material.albedo_color.a = 0.5
    
    # Check all children
    for child in node.get_children():
        _apply_transparency_to_mesh_scene(child)

# Clear all drag preview meshes
func clear_all_previews():
    for preview in drag_previews:
        preview.queue_free()
    drag_previews.clear()
    
    # Also clear the standard preview
    building_builder.clear_preview()

# Place components at all preview positions
func place_dragged_components():
    var cells = get_cells_in_drag()
    
    for cell_pos in cells:
        if not has_mesh_at_position(cell_pos):
            add_mesh(cell_pos, true)

    building_builder.navigation_region.bake_navigation_mesh()            
