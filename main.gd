extends Node3D

@export var camera: Camera3D
@export var plane: CSGBox3D
@onready var gridmap = $GridMap
@onready var building_builder = $BuildingBuilder
@onready var building_mouse_handler = $BuildingMouseHandler

func _ready():
	# Initialize the BuildingMouseHandler if it doesn't exist yet
	if not building_mouse_handler:
		building_mouse_handler = BuildingMouseHandler.new()
		building_mouse_handler.camera = camera
		building_mouse_handler.plane = plane
		building_mouse_handler.gridmap = gridmap
		building_mouse_handler.building_builder = building_builder
		add_child(building_mouse_handler)
	else:
		# Ensure BuildingMouseHandler has all the references it needs
		building_mouse_handler.camera = camera
		building_mouse_handler.plane = plane
		building_mouse_handler.gridmap = gridmap
		building_mouse_handler.building_builder = building_builder

func add_mesh(param_position: Vector3, is_plane: bool):
	building_mouse_handler.add_mesh(param_position, is_plane)

func has_mesh_at_position(param_position: Vector3) -> bool:
	return building_mouse_handler.has_mesh_at_position(param_position, gridmap)
