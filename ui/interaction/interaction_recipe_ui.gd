class_name InteractionRecipeUI extends Control

@export var interaction_handler: InteractionHandler

var recipe_inputs: Dictionary

var recipes_container: VBoxContainer
var selected_recipe_container: VBoxContainer

func _ready():
    var main_container = HBoxContainer.new()

    recipes_container = VBoxContainer.new()
    selected_recipe_container = VBoxContainer.new()

    main_container.add_child(recipes_container)
    main_container.add_child(selected_recipe_container)

    add_child(main_container)

func set_recipe(game_object: GameObject, interacter: Node3D, recipe_inputs_arg: Dictionary):
    reset()

    self.recipe_inputs = recipe_inputs_arg

    for recipe_input in recipe_inputs.values():
        var recipe_input_container = Button.new()
        recipe_input_container.text = recipe_input.get("label")
        recipes_container.add_child(recipe_input_container)

        recipe_input_container.pressed.connect(func():
            for child in selected_recipe_container.get_children():
                child.queue_free()

            var vertical_container = VBoxContainer.new()
            var label = Label.new()
            label.text = recipe_input.get("label")
            vertical_container.add_child(label)

            for child in recipe_input.get("inputs").values():
                var required_items = child.get("input").get("item")
                var output_items = child.get("output").get("item")

                var required_items_container = HBoxContainer.new()
                for required_item in required_items.values():
                    var item_key = required_item.get("item_key")
                    var item_quantity = required_item.get("quantity")

                    var item_label = Label.new()
                    item_label.text = item_key + " x " + str(item_quantity)
                    required_items_container.add_child(item_label)

                selected_recipe_container.add_child(required_items_container)

                var output_items_container = HBoxContainer.new()

                for output_item in output_items.values():
                    var item_key = output_item.get("item_key")
                    var item_quantity = output_item.get("quantity")

                    var item_label = Label.new()
                    item_label.text = item_key + " x " + str(item_quantity)
                    output_items_container.add_child(item_label)

                selected_recipe_container.add_child(output_items_container)

            var button = Button.new()
            button.text = "Process"
            button.pressed.connect(func():
                interaction_handler.launch_action(game_object, interacter, recipe_input.inputs.recipe)
            )
            vertical_container.add_child(button)
            selected_recipe_container.add_child(vertical_container)
            selected_recipe_container.show()
        )

func reset():
    selected_recipe_container.hide()
    for child in recipes_container.get_children():
        child.queue_free()

    for child in selected_recipe_container.get_children():
        child.queue_free()
        