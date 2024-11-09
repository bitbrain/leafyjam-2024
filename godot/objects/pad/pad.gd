extends RigidBody2D


var last_position:Vector2


func _ready() -> void:
	last_position = position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	last_position = position
