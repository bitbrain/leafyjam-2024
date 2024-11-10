extends Node2D


@export var player:Node2D


func _process(delta: float) -> void:
	global_position = player.get_custom_position()
