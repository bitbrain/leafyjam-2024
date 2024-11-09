class_name Player extends CharacterBody2D


@export var ACCELERATION = 1550
@export var FRICTION = 1520
@export var MAX_SPEED = 155


@onready var steerable_detector: Area2D = $SteerableDetector
@onready var sprite_2d: Sprite2D = $Sprite2D


var input_vector = Vector2.ZERO


var steerable:Area2D


func _ready() -> void:
	steerable_detector.area_entered.connect(_on_steerable_entered)
	steerable_detector.area_exited.connect(_on_steerable_exited)
	

func move(input_vector:Vector2) -> void:
	self.input_vector = input_vector.normalized()
	
	if self.input_vector.x != 0:
		sprite_2d.scale.x = 1 if input_vector.x < 0 else -1


func _physics_process(delta: float) -> void:
	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	move_and_slide()
	
	if steerable and input_vector != Vector2.ZERO:
		var force = Vector2(input_vector.x * 50, 0)  # Adjust the multiplier as needed
		steerable.get_parent().apply_central_force(force)
	
	
func _on_steerable_entered(area:Area2D) -> void:
	steerable = area
	
	
func _on_steerable_exited(area:Area2D) -> void:
	steerable = null
