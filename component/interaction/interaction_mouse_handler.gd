class_name InteractionMouseHandler extends Node

@export var camera: Camera3D
@export var interaction_range: float = 10.0  # Maximum distance for interaction
@export var interaction_handler: InteractionHandler

func _process(_delta):
    # Skip if building mode or UI interaction
    if GlobalBuilding.selected_component:
        return
        
    # Process interaction
    handle_interaction()

func handle_interaction():
    var is_left_click = Input.is_action_just_pressed("ui_left_click")
    var is_right_click = Input.is_action_just_pressed("ui_right_click")

    if !is_left_click and !is_right_click:
        return
    # Get mouse ray
    var mouse_pos = get_viewport().get_mouse_position()
    var from = camera.project_ray_origin(mouse_pos)
    var to = from + camera.project_ray_normal(mouse_pos) * 1000
    
    var space_state = camera.get_world_3d().direct_space_state
    var physics = PhysicsRayQueryParameters3D.new()
    physics.from = from
    physics.to = to
    
    var result = space_state.intersect_ray(physics)

    # Check for valid interaction
    if result and result.collider is StaticBody3D:
        # Found a StaticBody3D
        var body = result.collider
        print("Clicked on: ", body.name)
        
        # This is where your interaction logic would go
        # For example, check for workstation data
        if body.has_meta("component_data"):
            var click_type = "left" if is_left_click else "right"
            interaction_handler.handle_interaction(body, click_type)