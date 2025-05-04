extends Node

signal worker_grid_active_changed(active: bool)

var is_worker_grid_active: bool = false

func set_worker_grid_active(active: bool) -> void:
	is_worker_grid_active = active
	worker_grid_active_changed.emit(active)

