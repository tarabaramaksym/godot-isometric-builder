extends Node
class_name Inventory

signal inventory_changed
signal encumbered_status_changed(is_encumbered)

var items: Array = []
var current_weight: float = 0.0
var weight_max: float = 100.0
var encumbered_weight_threshold: float = 0.8 # 80% of max weight
var has_weight_max: bool = true
var is_encumbered: bool = false

func _init(has_max_weight: bool = true, max_weight: float = 100.0, encumbered_threshold: float = 0.8):
	has_weight_max = has_max_weight
	weight_max = max_weight
	encumbered_weight_threshold = encumbered_threshold
	
	# If no weight max, never encumbered
	if not has_weight_max:
		is_encumbered = false

func add_item(item: GameResource) -> bool:
	# Check if we can add this item (weight limits)
	if has_weight_max:
		var new_weight = current_weight + item.get_total_weight()
		if new_weight > weight_max:
			return false
	
	# If item is stackable, try to find existing stack
	if item.stackable:
		for existing_item in items:
			if existing_item.resource_id == item.resource_id and existing_item.quality == item.quality:
				# Same item type and quality, can stack
				existing_item.quantity += item.quantity
				_update_weight()
				emit_signal("inventory_changed")
				return true
	
	# If we got here, add as new item
	items.append(item.clone())
	_update_weight()
	emit_signal("inventory_changed")
	return true

func remove_item(item_index: int, quantity: int = 1) -> bool:
	if item_index < 0 or item_index >= items.size():
		return false
		
	var item = items[item_index]
	if item.quantity <= quantity:
		# Remove entire stack
		items.remove_at(item_index)
	else:
		# Remove partial stack
		item.quantity -= quantity
	
	_update_weight()
	emit_signal("inventory_changed")
	return true

func get_item(item_index: int) -> GameResource:
	if item_index < 0 or item_index >= items.size():
		return null
	return items[item_index]

func _update_weight():
	current_weight = 0.0
	for item in items:
		current_weight += item.get_total_weight()
	
	if has_weight_max:
		var was_encumbered = is_encumbered
		is_encumbered = current_weight >= (weight_max * encumbered_weight_threshold)
		
		if was_encumbered != is_encumbered:
			emit_signal("encumbered_status_changed", is_encumbered)

func get_total_value() -> float:
	var total = 0.0
	for item in items:
		total += item.get_total_value()
	return total

func get_item_count() -> int:
	return items.size()

func get_total_item_quantity() -> int:
	var total = 0
	for item in items:
		total += item.quantity
	return total

func has_space_for(item: GameResource) -> bool:
	if not has_weight_max:
		return true
		
	return current_weight + item.get_total_weight() <= weight_max

func clear():
	items.clear()
	current_weight = 0.0
	is_encumbered = false
	emit_signal("inventory_changed")
	emit_signal("encumbered_status_changed", false) 