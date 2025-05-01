extends CharacterBody3D

@export var navigation_agent: NavigationAgent3D
@export var navigation_region: NavigationRegion3D
var navigation_mesh: NavigationMesh

func _ready():
	navigation_mesh = navigation_region.navigation_mesh

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_accept"):
		var random_position := Vector3.ZERO
		random_position.x = randf_range(-5, 5)
		random_position.z = randf_range(-5, 5)
		navigation_agent.set_target_position(random_position)

func add_dynamic_obstacle(position_param: Vector3):
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = BoxMesh.new()
	mesh_instance.scale = Vector3(1, 2, 1)
	mesh_instance.global_position = position_param

	var nav_obstacle = NavigationObstacle3D.new()
	mesh_instance.add_child(nav_obstacle)

	var collision = CollisionShape3D.new()
	collision.shape = BoxShape3D.new()
	collision.shape.size = Vector3(1, 2, 1)
	mesh_instance.add_child(collision)

	navigation_region.add_child(mesh_instance)

	#navigation_region.bake_navigation_region()

func _physics_process(_delta):
	var destination = navigation_agent.get_next_path_position()
	var local_destination = destination - global_position
	var direction = local_destination.normalized()

	velocity = direction * 1.0
	move_and_slide()
