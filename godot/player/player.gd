class_name Player extends CharacterBody2D


@export var ACCELERATION = 150
@export var FRICTION = 1520
@export var MAX_SPEED = 55
@export var ROW_STRENGTH = 20.0


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
		if steerable.get_parent().is_sinking:
			return
		var force = Vector2(input_vector.x * ROW_STRENGTH, 0)  # Adjust the multiplier as needed
		steerable.get_parent().apply_central_force(force)
	
	
func _on_steerable_entered(area:Area2D) -> void:
	steerable = area
	steerable.get_parent().sinking.connect(_is_sinking)
	steerable.get_parent().immune_to_sinking = false
	
	
	
func _on_steerable_exited(area:Area2D) -> void:
	if steerable:
		steerable.get_parent().sinking.disconnect(_is_sinking)
	steerable = null
	
	
func _is_sinking() -> void:
	var objects = get_tree().get_first_node_in_group("Objects")
	var camera = get_tree().get_first_node_in_group("Camera") as Camera2D
	# HACK: avoid position smoothing to flicker screen
	camera.position_smoothing_enabled = false
	reparent(objects)
	camera.reset_smoothing()
	camera.position_smoothing_enabled = true
