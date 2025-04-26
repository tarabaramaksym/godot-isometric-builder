extends Node
class_name GameResource

# Base Properties
var resource_id: String = ""
var inherits: String = ""
var resource_name: String = ""
var description: String = ""
var icon: String = ""
var weight: float = 1.0
var base_value: float = 1.0

# Parent Properties
var stackable: bool = false
var has_quality: bool = false
var modifiers: Array = []

# Runtime Properties
var quantity: int = 1
var quality: int = 1
var current_modifiers: Array = []

func _init(id: String = "", quantity_val: int = 1, quality_val: int = 1):
	resource_id = id
	quantity = quantity_val
	quality = quality_val
	if id != "":
		_load_resource_data()

func _load_resource_data():
	var resource_data = GlobalFileResource.get_resource_data(resource_id)

	if resource_data != null:
		_apply_resource_data(resource_data)
		_apply_parent_data()

func _apply_resource_data(data: Dictionary):
	if data.has("name"): resource_name = data.name
	if data.has("description"): description = data.description
	if data.has("icon"): icon = data.icon
	if data.has("weight"): weight = data.weight
	if data.has("base_value"): base_value = data.base_value
	if data.has("inherits"): inherits = data.inherits

func _apply_parent_data():
	var parent_data = GlobalFileResource.get_resource_parent_data(inherits)

	if parent_data != null:
		if parent_data.has("stackable"): stackable = parent_data.stackable
		if parent_data.has("has_quality"): has_quality = parent_data.has_quality
		if parent_data.has("modifiers"): modifiers = parent_data.modifiers.duplicate()

func get_total_weight() -> float:
	return weight * quantity

func get_total_value() -> float:
	var value = base_value

	if has_quality:
		value *= (0.5 + (quality * 0.1))
	return value * quantity

func add_modifier(modifier: String):
	if not current_modifiers.has(modifier):
		current_modifiers.append(modifier)

func remove_modifier(modifier: String):
	current_modifiers.erase(modifier)

func has_modifier(modifier: String) -> bool:
	return current_modifiers.has(modifier)

func clone() -> GameResource:
	var new_resource = GameResource.new(resource_id, quantity, quality)

	new_resource.current_modifiers = current_modifiers.duplicate()

	return new_resource 