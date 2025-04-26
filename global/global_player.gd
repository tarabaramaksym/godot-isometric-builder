extends Node

@export var player: Player

func _ready():
	player = get_node("/root/Main/Player")

func get_player():
	return player
