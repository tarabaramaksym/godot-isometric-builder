class_name InteractionRecipeUI extends Control

var recipe_inputs: Dictionary

var interacter: Node3D
var recipes_container: VBoxContainer
var selected_recipe_container: VBoxContainer

func _ready():
    var main_container = HBoxContainer.new()

    recipes_container = VBoxContainer.new()
    selected_recipe_container = VBoxContainer.new()

    main_container.add_child(recipes_container)
    main_container.add_child(selected_recipe_container)

    add_child(main_container)

func set_recipe(recipe_inputs_arg: Dictionary):
    reset()

    self.recipe_inputs = recipe_inputs_arg

    for recipe_input in recipe_inputs.values():
        var recipe_input_container = Button.new()
        recipe_input_container.text = recipe_input.get("label")
        recipes_container.add_child(recipe_input_container)

        recipe_input_container.pressed.connect(func():
            for child in selected_recipe_container.get_children():
                child.queue_free()

            var label = Label.new()
            label.text = recipe_input.get("label")
            selected_recipe_container.add_child(label)
            selected_recipe_container.show()
        )

func reset():
    selected_recipe_container.hide()
    for child in recipes_container.get_children():
        child.queue_free()

    for child in selected_recipe_container.get_children():
        child.queue_free()
        