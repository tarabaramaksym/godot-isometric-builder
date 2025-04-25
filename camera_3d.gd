extends Camera3D

@export var pivot: Node3D
@export var min_zoom: float = 2.0
@export var max_zoom: float = 25.0
@export var zoom_speed: float = 0.5
@export var zoom_smoothing: float = 5.0
@export var rotation_speed: float = 0.005
@export var rotation_smoothing: float = 5.0
@export var vertical_rotation_limit: float = 0.8  # Limit in radians (approx 45 degrees)
@export var free_roam_speed: float = 10.0  # Speed for arrow key movement

var target_size: float = 15.0
var current_size: float = 15.0
var is_rotating: bool = false
var initial_pivot_rotation: Quaternion
var target_pivot_rotation: Quaternion
var orbit_distance: float
var free_roam_mode: bool = false
var original_pivot_position: Vector3

func _ready() -> void:
	# Set initial orthographic size
	current_size = target_size
	size = current_size
	initial_pivot_rotation = pivot.quaternion
	target_pivot_rotation = pivot.quaternion
	
	# Store the initial distance from the pivot
	orbit_distance = global_transform.origin.distance_to(pivot.global_transform.origin)
	original_pivot_position = pivot.global_position

func _process(delta: float) -> void:
	# Smooth zoom transition
	if not is_equal_approx(current_size, target_size):
		current_size = lerp(current_size, target_size, zoom_smoothing * delta)
		size = current_size
	
	# Smooth rotation restoration when not rotating
	if not is_rotating and pivot.quaternion != target_pivot_rotation:
		pivot.quaternion = pivot.quaternion.slerp(target_pivot_rotation, rotation_smoothing * delta)
		
	# Make sure camera maintains its position relative to pivot
	# This ensures we're always looking at the player/pivot point
	update_camera_position()
	
	# Handle arrow key movement for free roam
	handle_free_roam(delta)

func update_camera_position() -> void:
	# Setup the camera to orbit around the pivot point
	# The camera's forward direction is the direction it's looking
	var forward = -global_transform.basis.z.normalized()
	
	# Set the camera position based on the pivot position and the forward direction
	global_transform.origin = pivot.global_transform.origin - forward * orbit_distance

func handle_free_roam(delta: float) -> void:
	# Move the pivot point with arrow keys
	var move_dir = Vector3.ZERO
	
	if Input.is_action_pressed("ui_right"):
		move_dir.x += 1
	if Input.is_action_pressed("ui_left"):
		move_dir.x -= 1
	if Input.is_action_pressed("ui_up"):
		move_dir.z -= 1
	if Input.is_action_pressed("ui_down"):
		move_dir.z += 1
		
	# If we're moving
	if move_dir != Vector3.ZERO:
		free_roam_mode = true
		# Transform to camera's local coordinates
		var camera_basis = global_transform.basis
		var movement = (camera_basis.x * move_dir.x + camera_basis.z * move_dir.z).normalized()
		# Only move on XZ plane
		movement.y = 0
		
		# Apply movement to pivot
		pivot.global_position += movement * free_roam_speed * delta

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			# Zoom in
			zoom_camera(-zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			# Zoom out
			zoom_camera(zoom_speed)
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				# Start rotation
				is_rotating = true
				initial_pivot_rotation = pivot.quaternion
			else:
				# Stop rotation and start restoration
				is_rotating = false
				target_pivot_rotation = initial_pivot_rotation
	
	elif event is InputEventMouseMotion and is_rotating:
		# Store original distance
		var original_distance = global_transform.origin.distance_to(pivot.global_transform.origin)
		
		# Rotate around Y-axis (horizontal)
		rotate_y(-event.relative.x * rotation_speed)
		
		# Calculate proposed rotation for vertical movement
		var current_rotation_x = rotation.x
		var proposed_rotation_x = current_rotation_x - event.relative.y * rotation_speed
		
		# Apply vertical rotation only if within limits
		if abs(proposed_rotation_x) < vertical_rotation_limit:
			rotate_x(-event.relative.y * rotation_speed)
			
		# Update camera position to maintain orbit
		update_camera_position()
	
	# Handle Home key to reset camera to original position
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_HOME:
			reset_camera_position()

func zoom_camera(zoom_amount: float) -> void:
	# Calculate new target size
	target_size = clamp(target_size + zoom_amount, min_zoom, max_zoom)

func reset_camera_position() -> void:
	# Reset pivot to original position
	pivot.global_position = original_pivot_position
	free_roam_mode = false
