class_name Player extends CharacterBody3D

@export var speed := 5.0
@export var jump_velocity := 6.0
@export var gravity := 9.8
@export var camera: Camera3D  # Assign in editor
@export var inventory: Inventory
@export var navigation_agent: NavigationAgent3D

var is_path_moving := false
var finished_path_callback: Callable

func _physics_process(delta):
    var input_dir = Input.get_vector("left", "right", "down", "up")

    if input_dir != Vector2.ZERO and is_path_moving:
        is_path_moving = false
    
    if is_path_moving:
        var destination = navigation_agent.get_next_path_position()
        var local_destination = destination - global_position
        var direction = local_destination.normalized()

        velocity = direction * speed
        move_and_slide()

        if destination.distance_to(global_position) < GlobalConfig.action_proximity:
            is_path_moving = false
            finished_path_callback.call()

        return

    if input_dir != Vector2.ZERO:
        # Get camera directions
        var cam_forward = -camera.global_transform.basis.z
        var cam_right = camera.global_transform.basis.x

        # Flatten to XZ plane
        cam_forward.y = 0
        cam_right.y = 0
        cam_forward = cam_forward.normalized()
        cam_right = cam_right.normalized()

        var move_dir = (cam_forward * input_dir.y + cam_right * input_dir.x).normalized()
        velocity.x = move_dir.x * speed
        velocity.z = move_dir.z * speed
    else:
        velocity.x = 0
        velocity.z = 0

    if not is_on_floor():
        velocity.y -= gravity * delta

    move_and_slide()


func move_to(target: Vector3, callback: Callable):
    navigation_agent.set_target_position(target)
    is_path_moving = true
    finished_path_callback = callback
