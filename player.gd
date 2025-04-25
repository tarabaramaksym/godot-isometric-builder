extends CharacterBody3D

@export var speed := 5.0
@export var jump_velocity := 6.0
@export var gravity := 9.8
@export var camera: Camera3D  # Assign in editor

func _physics_process(delta):
	var input_dir = Input.get_vector("left", "right", "down", "up")

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
