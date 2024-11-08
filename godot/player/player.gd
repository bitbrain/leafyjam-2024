class_name Player extends CharacterBody2D


@export var ACCELERATION = 550
@export var FRICTION = 70
@export var MAX_SPEED = 75


var input_vector = Vector2.ZERO
	

func move(input_vector:Vector2) -> void:
	self.input_vector = input_vector.normalized()


func _physics_process(delta: float) -> void:
	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	move_and_slide()
