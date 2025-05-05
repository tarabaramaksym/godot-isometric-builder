extends Node3D

@export var camera: Camera3D
@export var gridmap: GridMap
@export var building_builder: BuildingBuilder
@export var building_mouse_handler: BuildingMouseHandler

func _process(_delta):
	if Input.is_action_just_pressed("save"):
		save_all_buildings()
	if Input.is_action_just_pressed("load"):
		load_all_buildings()

func add_mesh(param_position: Vector3, is_plane: bool):
	building_mouse_handler.add_mesh(param_position, is_plane)

func has_mesh_at_position(param_position: Vector3) -> bool:
	return building_mouse_handler.has_mesh_at_position(param_position)

func clear_all_buildings():
	building_builder.clear_all_buildings()
	
func save_all_buildings():
	var buildings_to_save = []
	
	for child in gridmap.get_children():
		var isBuilding = child is BuildingGameObject or child is InteractiveGameObject
		if isBuilding:
			buildings_to_save.append(child.save())
	
	GlobalSaveManager.save_buildings(buildings_to_save)

func load_all_buildings():
	for child in gridmap.get_children():
		var isBuilding = child is BuildingGameObject or child is InteractiveGameObject
		if isBuilding:
			child.queue_free()
			
	building_builder.load_buildings()
