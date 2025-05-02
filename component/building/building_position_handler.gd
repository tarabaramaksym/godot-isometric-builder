class_name BuildingPositionHandler extends Node3D


# Update the position of a preview instance
func update_preview_position(preview_instance: Node3D, preview_position: Vector3, component_data: Dictionary):
    if not preview_instance:
        return
    
    # Set the base position with grid offset
    preview_instance.transform.origin = preview_position	
    
    # Get the first child's mesh for height calculation (matches behavior in create_simple_mesh)
    if component_data.mesh_type == "simple" and not "position" in component_data:
        # Find mesh instance to get size
        for child in preview_instance.get_children():
            if child is MeshInstance3D and child.mesh is BoxMesh:
                # Apply the same height offset used in create_simple_mesh
                preview_instance.transform.origin.y += child.mesh.size.y / 2
                break
    # For load mesh type, no special positioning is needed as the model is already positioned correctly
    # Unless there are specific positioning rules in the component data
    elif component_data.mesh_type == "load" and "position" in component_data:
        var pos = component_data.position
        preview_instance.transform.origin += Vector3(pos[0], pos[1], pos[2])

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
func setup_mesh_position(root_node: Node3D, body_position: Vector3, rotation_param: float):
    root_node.transform.origin = body_position
    root_node.rotation_degrees.y = rotation_param





