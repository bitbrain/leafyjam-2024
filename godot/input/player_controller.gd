extends Node2D

@export var player:Node2D

var input_vector:Vector2 = Vector2(0, 0)

func _physics_process(delta: float) -> void:
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	player.move(input_vector)
