class_name InteractionRecipe extends Node

@export var recipe_ui: InteractionRecipeUI

var interacter: Node3D

func launch_recipe(interacter_arg: Node3D, recipe_inputs: Dictionary):
    self.interacter = interacter_arg

    recipe_ui.set_recipe(recipe_inputs) 
    recipe_ui.show()

func hide_ui():
    recipe_ui.reset()
    recipe_ui.hide()

