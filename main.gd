extends Node3D

@export var camera: Camera3D
@export var plane: CSGBox3D
@onready var highlight = $Highlight
@onready var gridmap = $GridMap
@onready var building_builder = $BuildingBuilder

func _ready():
	# If BuildingBuilder isn't already in the scene, create it
	if not building_builder:
		building_builder = BuildingBuilder.new()
		add_child(building_builder)
	
	# Hide the highlight as we'll use the preview instead
	if highlight:
		highlight.visible = false

func add_mesh(bodyPosition: Vector3):
	building_builder.add_mesh(bodyPosition, gridmap)

var debug_output ='';

var lastMat

func has_mesh_at_position(position: Vector3) -> bool:
	return building_builder.has_mesh_at_position(position, gridmap)

func _process(delta):
	# Check for rotation input
	if Input.is_action_just_pressed("rotate") and not GlobalBuilding.ui_interaction:
		building_builder.rotate_component()
		print('rotate')
	
	if GlobalBuilding.ui_interaction:
		building_builder.clear_preview()
		return

	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000

	var space_state = get_world_3d().direct_space_state
	var physics = PhysicsRayQueryParameters3D.new()
	physics.from = from
	physics.to = to

	var result = space_state.intersect_ray(physics)
	
	if result and result.collider == plane:
		var world_pos = result.position
		var cell = gridmap.local_to_map(world_pos)
		var cell_world_pos = gridmap.map_to_local(cell)

		if not GlobalBuilding.selected_component.is_empty():
			if not building_builder.has_preview():
				building_builder.update_preview()
			building_builder.update_preview_position(cell_world_pos)
		
		if Input.is_action_just_pressed("ui_left_click"):
			if not has_mesh_at_position(cell_world_pos):
				add_mesh(cell_world_pos)
		
	elif result and result.collider is StaticBody3D:
		var normal = result.normal
		# Only allow placement on top surfaces
		if normal.dot(Vector3.UP) > 0.99:
			var world_pos = result.position
			var cell = gridmap.local_to_map(world_pos)
			var cell_world_pos = gridmap.map_to_local(cell)
			
			# Update preview position
			if not GlobalBuilding.selected_component.is_empty():

				if not building_builder.has_preview():
					building_builder.update_preview()
				building_builder.update_preview_position(cell_world_pos)

			if Input.is_action_just_pressed("ui_left_click"):
				#if not has_mesh_at_position(cell_world_pos):
				add_mesh(cell_world_pos)
		else:
			building_builder.clear_preview()
	else:
		building_builder.clear_preview()
