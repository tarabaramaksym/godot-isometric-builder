class_name WorkerAgent extends CharacterBody3D

@export var inventory: Inventory
@export var speed := 5.0
@export var gravity := 9.8
@export var navigation_agent: NavigationAgent3D

var instructions: Array = []

var is_path_moving := false
var finished_path_callback: Callable

func _ready():
    inventory = get_node("Inventory")
    var axe = ItemGameObject.new()
    axe.quantity = 1
    axe.initialize_game_object("axe", {})

    var pickaxe = ItemGameObject.new()
    pickaxe.quantity = 1
    pickaxe.initialize_game_object("pickaxe", {})

    inventory.add_item(axe)
    inventory.add_item(pickaxe)

func _physics_process(_delta):
    if is_path_moving:
        var destination = navigation_agent.get_next_path_position()
        var local_destination = destination - global_position
        var direction = local_destination.normalized()

        velocity = direction * speed
        move_and_slide()

        if destination.distance_to(global_position) < GlobalConfig.action_proximity:
            is_path_moving = false
            finished_path_callback.call()

func move_to(target: Vector3, callback: Callable):
    navigation_agent.set_target_position(target)
    is_path_moving = true
    finished_path_callback = callback