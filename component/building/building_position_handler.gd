class_name BuildingPositionHandler extends Node3D

# Calculate grid offset for component positioning
func calculate_grid_offset(component_data: Dictionary, current_size_values: Dictionary) -> Vector3:
    var offset = Vector3.ZERO
    
    if component_data.mesh_type == "simple":
        if "base_mesh_size" in component_data:
            var base_size = component_data.base_mesh_size
            var current_size = Vector3(
                current_size_values.get("x", base_size[0]),
                current_size_values.get("y", base_size[1]),
                current_size_values.get("z", base_size[2])
            )
            
            # Calculate offset to keep the bottom-center fixed on grid
            # The offset depends on which dimensions can be changed
            # Commented out but can be re-enabled if needed
            # if "x" in current_size_values:
            #     # Check if width is even (using int conversion)
            #     if int(current_size.x) % 2 == 0:
            #         # Even width needs 0.5 grid offset in x
            #         offset.x = 0.5
            
            # if "z" in current_size_values:
            #     # Check if depth is even (using int conversion)
            #     if int(current_size.z) % 2 == 0:
            #         # Even depth needs 0.5 grid offset in z
            #         offset.z = 0.5
            
            # if "y" in current_size_values:
            #     # Check if height is even (using int conversion)
            #     if int(current_size.y) % 2 == 0:
            #         # Even height needs 0.5 grid offset in y
            #         offset.y = 0.5
    
    return offset

# Update the position of a preview instance
func update_preview_position(preview_instance: Node3D, position: Vector3, component_data: Dictionary, current_size_values: Dictionary):
    if not preview_instance:
        return
    
    var offset = calculate_grid_offset(component_data, current_size_values)
    
    # Set the base position with grid offset
    preview_instance.transform.origin = position + offset
    
    # Get the first child's mesh for height calculation (matches behavior in create_simple_mesh)
    if component_data.mesh_type == "simple" and not "position" in component_data:
        # Find mesh instance to get size
        for child in preview_instance.get_children():
            if child is MeshInstance3D and child.mesh is BoxMesh:
                # Apply the same height offset used in create_simple_mesh
                preview_instance.transform.origin.y += child.mesh.size.y / 2
                break

# Apply position offset for simple meshes
func apply_simple_mesh_position(root_node: Node3D, mesh_size: Vector3, component_data: Dictionary, is_drag_preview: bool = false):
    # If no y-centered mesh, add an offset ONLY for non-drag previews
    # For drag previews, this will be handled by the main script
    if not "position" in component_data and not is_drag_preview:
        # Half height offset to place bottom face at y=0
        root_node.transform.origin.y += (mesh_size.y / 2)

# Apply position for array mesh parts
func apply_array_part_position(part_container: Node3D, mesh_data: Dictionary):
    # Set position if specified in mesh data
    if "position" in mesh_data:
        var pos = mesh_data.position
        part_container.transform.origin = Vector3(pos[0], pos[1], pos[2])

# Check if a mesh exists at a specific position
func has_mesh_at_position(position_mesh: Vector3, parent_node: Node) -> bool:
    for wall in parent_node.get_children():
        if wall is Node3D and wall.transform.origin.is_equal_approx(position_mesh):
            return true
    return false

# Set up the position for a new mesh at a given position
func setup_mesh_position(root_node: Node3D, body_position: Vector3, offset: Vector3, rotation: float):
    root_node.transform.origin = body_position + offset
    root_node.rotation_degrees.y = rotation





