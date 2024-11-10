class_name Player extends CharacterBody2D


signal acorn_collected(position:Vector2)


@export var ACCELERATION = 150
@export var FRICTION = 1520
@export var MAX_SPEED = 155
@export var ROW_STRENGTH = 620.0
@export var ROW_INTERVAL = 1.0
@export var STREAM_VELOCITY = Vector2(0, 2550)


@onready var steerable_detector: Area2D = $SteerableDetector
@onready var boarding_detecor: Area2D = $BoardingDetecor
@onready var sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var boarded_shape: CollisionShape2D = %BoardedShape
@onready var swimming_shape: CollisionShape2D = %SwimmingShape
@onready var acorn_detector: Area2D = $AcornDetector


enum AnimationState { ROW, ROW_WAIT, STAND }


var input_vector = Vector2.ZERO
var row_vector = Vector2.ZERO
var time_since_last_row = ROW_INTERVAL


var steerable:Area2D
var hopping = false
var current_state = AnimationState.STAND


func _ready() -> void:
	steerable_detector.area_entered.connect(_on_steerable_entered)
	steerable_detector.area_exited.connect(_on_steerable_exited)
	boarding_detecor.area_entered.connect(_hop_on)
	acorn_detector.body_entered.connect(_collect_acorn)
	sprite_2d.animation_looped.connect(_on_animation_looped)
	

func move(input_vector:Vector2) -> void:
	self.input_vector = input_vector.normalized()
	
	if self.input_vector.x != 0:
		sprite_2d.scale.x = 1 if input_vector.x < 0 else -1
		
		
func _process(delta: float) -> void:
	time_since_last_row += delta


func _physics_process(delta: float) -> void:
	if steerable == null and input_vector == Vector2.ZERO:
		# Drift with the stream at a constant speed when no input and no steerable object
		velocity = STREAM_VELOCITY * delta
	else:
		if input_vector != Vector2.ZERO:
			velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		
	move_and_slide()

	if steerable and input_vector != Vector2.ZERO:
		if steerable.get_parent().is_sinking:
			return
		row_vector = input_vector
		if _can_row():
			_row()
			time_since_last_row = 0
		
	
	
func _on_steerable_entered(area:Area2D) -> void:
	steerable = area
	steerable.get_parent().sunk.connect(_hop_off)
	steerable.get_parent().immune_to_sinking = false
	
	
	
func _on_steerable_exited(area:Area2D) -> void:
	if steerable:
		steerable.get_parent().sunk.disconnect(_hop_off)
	steerable = null
	
	
func _hop_off() -> void:
	# HACK: avoid error during physics process
	_hop_off_steerable.call_deferred()
	
func _hop_on(area:Area2D) -> void:
	if hopping:
		# already hopping -> don't hop!
		return
	var parent = area.get_parent()
	if parent.is_sinking:
		return
	if steerable == area:
		# nothing to hop on to -> already hopped on
		return
	# HACK: avoid error during physics process
	hopping = true
	_hop_on_steerable.call_deferred(parent)
	
	
func _hop_off_steerable() -> void:
	var objects = get_tree().get_first_node_in_group("Objects")
	var camera = get_tree().get_first_node_in_group("Camera") as Camera2D
	# HACK: avoid position smoothing to flicker screen
	camera.position_smoothing_enabled = false
	reparent(objects)
	camera.reset_smoothing()
	camera.position_smoothing_enabled = true
	swimming_shape.disabled = false
	boarded_shape.disabled = true
	
	
func _hop_on_steerable(steerable:Node2D) -> void:
	var camera = get_tree().get_first_node_in_group("Camera") as Camera2D
	# HACK: avoid position smoothing to flicker screen
	camera.position_smoothing_enabled = false
	reparent(steerable)
	var position_delta = steerable.global_position - global_position
	sprite_2d.offset = position_delta
	sprite_2d.offset.y *= -1.0
	sprite_2d.offset.x *= -sprite_2d.scale.x
	var move_sprite_to_position_tween = create_tween()
	move_sprite_to_position_tween.tween_property(sprite_2d, "offset", Vector2.ZERO, 0.25)\
	.finished.connect(func():hopping = false)
	global_position = steerable.global_position
	camera.reset_smoothing()
	camera.position_smoothing_enabled = true
	swimming_shape.disabled = true
	boarded_shape.disabled = false
	time_since_last_row = ROW_INTERVAL
	
	
func _can_row() -> bool:
	return time_since_last_row >= ROW_INTERVAL


func _row() -> void:
	if steerable:
		var force = Vector2(row_vector.x * ROW_STRENGTH, max(0.0, row_vector.y * ROW_STRENGTH))
		steerable.get_parent().apply_central_force(force)
		play_animation(AnimationState.ROW)
		
		
func _collect_acorn(acorn:Node2D) -> void:
	acorn_collected.emit(acorn.global_position)
	acorn.queue_free()
	
	
func play_animation(state: AnimationState):
	current_state = state
	match state:
		AnimationState.ROW:
			sprite_2d.play("Row")
		AnimationState.ROW_WAIT:
			sprite_2d.play("Row-wait")
		AnimationState.STAND:
			sprite_2d.play("Stand")


func _on_animation_looped():
	match current_state:
		AnimationState.ROW:
			play_animation(AnimationState.ROW_WAIT)
		AnimationState.ROW_WAIT:
			play_animation(AnimationState.STAND)
