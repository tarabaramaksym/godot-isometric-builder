extends Camera3D

@export var pivot: Node3D
@export var min_zoom: float = 2.0
@export var max_zoom: float = 25.0
@export var zoom_speed: float = 0.5
@export var zoom_smoothing: float = 5.0
@export var free_roam_speed: float = 10.0  # Speed for arrow key movement
@export var rotation_speed: float = 0.5  # Speed for rotation

var target_size: float = 15.0
var current_size: float = 15.0
var orbit_distance: float
var free_roam_mode: bool = false
var original_pivot_position: Vector3
var rotating: bool = false
var last_mouse_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Set initial orthographic size
	current_size = target_size
	size = current_size
	
	# Store the initial distance from the pivot
	orbit_distance = global_transform.origin.distance_to(pivot.global_transform.origin)
	original_pivot_position = pivot.global_position

func _process(delta: float) -> void:
	# Smooth zoom transition
	if not is_equal_approx(current_size, target_size):
		current_size = lerp(current_size, target_size, zoom_smoothing * delta)
		size = current_size
	
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
			# Start/stop rotation
			rotating = event.pressed
			if rotating:
				last_mouse_position = event.position
	
	# Handle mouse movement for rotation
	elif event is InputEventMouseMotion and rotating:
		handle_rotation(event)
	
	# Handle Home key to reset camera to original position
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_HOME:
			reset_camera_position()

func handle_rotation(event: InputEventMouseMotion) -> void:
	# Calculate mouse movement delta
	var delta = event.position - last_mouse_position
	last_mouse_position = event.position
	
	# Apply horizontal rotation (around Y axis) to the pivot
	# We only want rotation around the global Y axis for horizontal movement
	var rotation_y = delta.x * rotation_speed * 0.01
	
	# Create a transform that rotates around the global Y axis
	var rot_transform = Transform3D().rotated(Vector3.UP, rotation_y)
	
	# Apply the rotation to the pivot's transform
	pivot.transform = rot_transform * pivot.transform

func zoom_camera(zoom_amount: float) -> void:
	# Calculate new target size
	target_size = clamp(target_size + zoom_amount, min_zoom, max_zoom)

func reset_camera_position() -> void:
	# Reset pivot to original position
	pivot.global_position = original_pivot_position
	free_roam_mode = false
