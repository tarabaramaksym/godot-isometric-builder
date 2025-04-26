class_name BuildingBuilder extends Node3D

signal size_options_changed(options)

@export var highlight: Highlight

var building_components = {}
var workstation_components = {}
var current_size_options = {}
var current_size_values = {}
var preview_instance = null
var current_rotation = 0  # Store rotation in degrees

# Position handler for all positioning logic
var position_handler = BuildingPositionHandler.new()

func _ready():
	# Add position handler
	add_child(position_handler)
	
	building_components = GlobalFileBuilding.load_component_data().duplicate()
	building_components.merge(GlobalFileWorkstation.load_workstation_data())
	building_components.merge(GlobalFileNature.load_nature_data())

	# Initialize with default selected component if present
	if not GlobalBuilding.selected_component.is_empty() and is_valid_component():
		update_size_options(GlobalBuilding.selected_component)

func update_size_options(component_name):
	current_size_options.clear()
	current_size_values.clear()
	
	# Reset rotation when changing components
	reset_rotation()
	
	if component_name.is_empty() or not building_components.has(component_name):
		emit_signal("size_options_changed", {})
		return
	
	var component_data = building_components[component_name]
	
	# Check if component has size options
	if "size_options" in component_data:
		for option_set in component_data.size_options:
			# Process x, y, z options if they exist
			for axis in ["x", "y", "z"]:
				if axis in option_set:
					var axis_data = option_set[axis]
					current_size_options[axis] = {
						"min": axis_data.min,
						"max": axis_data.max
					}
					# Set default values to minimum
					current_size_values[axis] = axis_data.min
	
	# Emit signal with the options
	emit_signal("size_options_changed", current_size_options)
	
	# Update preview if component changed
	update_preview()

func set_size_value(axis, value):
	if axis in current_size_options and value >= current_size_options[axis].min and value <= current_size_options[axis].max:
		current_size_values[axis] = value
		update_preview()

func update_preview():
	clear_preview()
	
	# If no valid component, exit
	if GlobalBuilding.selected_component.is_empty() or not is_valid_component():
		return
	
	# Create new preview
	var component_data = building_components[GlobalBuilding.selected_component]
	preview_instance = StaticBody3D.new()
	preview_instance.name = "PreviewMesh"
	
	# Set initial position to origin (will be updated later)
	preview_instance.transform.origin = Vector3.ZERO
	
	# Apply current rotation
	preview_instance.rotation_degrees.y = current_rotation
	
	# Create mesh based on component type
	if component_data.mesh_type == "simple":
		create_simple_mesh(preview_instance, component_data, true)
	elif component_data.mesh_type == "array":
		create_array_mesh(preview_instance, component_data, true)
	
	add_child(preview_instance)

func clear_preview():
	if preview_instance:
		preview_instance.queue_free()
		preview_instance = null

# Update the position of the preview
func update_preview_position(position: Vector3):
	if preview_instance:
		if GlobalBuilding.selected_component.is_empty() or not is_valid_component():
			return
			
		var component_data = building_components[GlobalBuilding.selected_component]
		
		# Use position handler
		position_handler.update_preview_position(
			preview_instance,
			position,
			component_data,
			current_size_values
		)

func calculate_grid_offset(component_data: Dictionary) -> Vector3:
	# Use position handler
	return position_handler.calculate_grid_offset(component_data, current_size_values)

# Check if preview is active
func has_preview():
	return preview_instance != null

func add_mesh(bodyPosition: Vector3, parent_node: Node, is_plane = true):
	# Get the selected component from global
	var component_name = GlobalBuilding.selected_component
	
	# If no component selected or not found in data, return
	if component_name.is_empty() or not building_components.has(component_name):
		print("No valid component selected")
		return null
	
	var component_data = building_components[component_name]
	
	# Calculate grid alignment offset using position handler
	var offset = position_handler.calculate_grid_offset(component_data, current_size_values)
	
	# Create root node (StaticBody3D)
	var root = StaticBody3D.new()
		
	if "can_be_interacted" in component_data:
		root.set_meta("component_data", component_data)
	
	# Setup position using position handler
	position_handler.setup_mesh_position(root, bodyPosition, offset, current_rotation)
	
	# Create mesh based on component type
	if component_data.mesh_type == "simple":
		create_simple_mesh(root, component_data)
	elif component_data.mesh_type == "array":
		create_array_mesh(root, component_data)
	
	# Add the component to the scene
	parent_node.add_child(root)
	return root

func create_simple_mesh(root_node: Node3D, component_data: Dictionary, is_preview = false, is_drag_preview = false):
	# Create the specified mesh type
	var meshChild
	if component_data.mesh == "BoxMesh3D":
		meshChild = BoxMesh.new()
		
		# Set size from base_mesh_size if available
		if "base_mesh_size" in component_data:
			var size = component_data.base_mesh_size
			var base_size = Vector3(size[0], size[1], size[2])
			
			# Apply custom size values directly
			meshChild.size = Vector3(
				current_size_values.get("x", base_size.x),
				current_size_values.get("y", base_size.y),
				current_size_values.get("z", base_size.z)
			)
		else:
			# Default size if no base_mesh_size specified
			meshChild.size = Vector3(1, 1, 1)

	# Create mesh instance
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = meshChild
	
	# Create a material
	var material = StandardMaterial3D.new()
	
	if is_preview:
		# Semi-transparent material for preview
		material.albedo_color = Color(0.8, 0.8, 0.8, 0.5)
		material.flags_transparent = true
	else:
		material.albedo_color = Color(0.8, 0.8, 0.8)
		
		# Add collision shape if not a preview and collider type is specified
		if "collider" in component_data and component_data.collider == "simple":
			var collision_shape = CollisionShape3D.new()
			var shape = BoxShape3D.new()
			shape.size = meshChild.size
			collision_shape.shape = shape
			collision_shape.transform.origin = Vector3(0, 0, 0) # At center of mesh
			root_node.add_child(collision_shape)

	if "rgb_color" in component_data:
		# Approach 1: If rgb_color is an array of numbers [r, g, b]
		if component_data.rgb_color is Array and component_data.rgb_color.size() >= 3:
			material.albedo_color = Color(
				component_data.rgb_color[0] / 255.0, 
				component_data.rgb_color[1] / 255.0, 
				component_data.rgb_color[2] / 255.0, 
				1.0  # Full opacity
			)
		# Approach 2: If rgb_color is a string like "#FF0000"
		elif component_data.rgb_color is String:
			material.albedo_color = Color(component_data.rgb_color)
		# Approach 3: If rgb_color is already a Color object
		elif component_data.rgb_color is Color:
			material.albedo_color = component_data.rgb_color
	
	mesh_instance.material_override = material
	
	# Apply position using position handler
	position_handler.apply_simple_mesh_position(
		root_node, 
		meshChild.size, 
		component_data, 
		is_drag_preview
	)

	if !is_preview and !is_drag_preview:
		highlight.assign_highlight(component_data, root_node, mesh_instance)
	
	# Add mesh to container
	root_node.add_child(mesh_instance)

func create_array_mesh(root_node: Node3D, component_data: Dictionary, is_preview = false):
	# Handle array-type meshes (like stairs)
	var mesh_array = component_data.mesh
	
	for mesh_data in mesh_array:
		# Create a container for each part
		var part_container = Node3D.new()
		part_container.name = "PartContainer"
		
		# Apply position using position handler
		position_handler.apply_array_part_position(part_container, mesh_data)
		
		# Create the specified mesh type
		var meshChild
		if mesh_data.mesh == "BoxMesh3D":
			meshChild = BoxMesh.new()
			
			# Set size from base_mesh_size if available
			if "base_mesh_size" in mesh_data:
				var size = mesh_data.base_mesh_size
				var base_size = Vector3(size[0], size[1], size[2])
				
				# Apply custom size values
				meshChild.size = Vector3(
					current_size_values.get("x", base_size.x),
					base_size.y,
					base_size.z
				)
		
		# Create mesh instance
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = meshChild
		
		# Create a material
		var material = StandardMaterial3D.new()
		
		if is_preview:
			# Semi-transparent material for preview
			material.albedo_color = Color(0.8, 0.8, 0.8, 0.5)
			material.flags_transparent = true
		else:
			material.albedo_color = Color(0.8, 0.8, 0.8)
			
			# Add collision shape if not a preview and collider type is specified
			if "collider" in mesh_data and mesh_data.collider == "simple":
				var collision_shape = CollisionShape3D.new()
				var shape = BoxShape3D.new()
				shape.size = meshChild.size
				collision_shape.shape = shape
				part_container.add_child(collision_shape)
		
		mesh_instance.material_override = material
		
		# Add mesh instance to part container
		part_container.add_child(mesh_instance)
		
		# Add part container to root node
		root_node.add_child(part_container)

# Helper function to add collision shapes
func add_collision_shape(root_node: Node3D, size: Vector3, position: Vector3):
	var collision_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	
	# Set size of the collision shape
	shape.size = size
	collision_shape.shape = shape
	
	# Set position to match the mesh
	collision_shape.transform.origin = position
	
	# Add to the parent node
	root_node.add_child(collision_shape)

func has_mesh_at_position(positionMesh: Vector3, parent_node: Node) -> bool:
	# Use position handler
	return position_handler.has_mesh_at_position(positionMesh, parent_node)

# Reset rotation when changing components
func reset_rotation():
	current_rotation = 0
	if preview_instance:
		preview_instance.rotation_degrees.y = current_rotation

# Rotate the current component by 90 degrees
func rotate_component():
	current_rotation = (current_rotation + 90) % 360
	if preview_instance:
		preview_instance.rotation_degrees.y = current_rotation
	print("Rotated to: ", current_rotation, " degrees")

# Create a preview instance without adding it to the scene, but without position adjustments
func create_preview_instance() -> Node3D:
	# If no valid component, exit
	if GlobalBuilding.selected_component.is_empty() or not is_valid_component():
		return null
	
	# Create new preview
	var component_data = building_components[GlobalBuilding.selected_component]
	var preview = StaticBody3D.new()
	preview.name = "DragPreviewMesh"
	
	# Apply current rotation
	preview.rotation_degrees.y = current_rotation
	
	# Create mesh based on component type, but DO NOT apply position offset in create_simple_mesh
	# The offset will be applied by the caller
	var is_drag_preview = true
	if component_data.mesh_type == "simple":
		create_simple_mesh(preview, component_data, true, is_drag_preview)
	elif component_data.mesh_type == "array":
		create_array_mesh(preview, component_data, true)
	
	return preview


func is_valid_component() -> bool:
	var selected_component = GlobalBuilding.selected_component

	return building_components.has(selected_component)
