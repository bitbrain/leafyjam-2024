class_name Player extends CharacterBody2D


const AcornScene = preload("res://objects/acorn/acorn.tscn")


signal acorn_collected(acorn:Node2D)
signal acorn_dropped()


@export var ACCELERATION = 150
@export var FRICTION = 1520
@export var MAX_SPEED = 155
@export var ROW_STRENGTH = 1000.0
@export var ROW_INTERVAL = 1.0
@export var STREAM_VELOCITY = Vector2(0, 2550)
@export var DAMAGE = 15
@export var DAMAGE_TICKRATE = 0.2:
	set(dt):
		DAMAGE_TICKRATE = dt
		damage_timer.wait_time = DAMAGE_TICKRATE
@export var DROP_RADIUS = 80


@onready var steerable_detector: Area2D = $SteerableDetector
@onready var boarding_detecor: Area2D = $BoardingDetecor
@onready var sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var boarded_shapes: Array[CollisionShape2D] = [%BoardedShape, %BoardedDamageShape]
@onready var swimming_shapes: Array[CollisionShape2D] = [%SwimmingShape, %SwimmingDamageShape]

@onready var acorn_detector: Area2D = $AcornDetector
@onready var damage_detector: Area2D = $DamageDetector
@onready var damage_timer: Timer = $DamageTimer
@onready var gameobjects = get_tree().get_first_node_in_group("Objects")
@onready var splash_sound: Node2D = $SplashSound
@onready var land_on_pad_sound: AudioStreamPlayer2D = $LandOnPadSound
@onready var row_sound: AudioStreamPlayer2D = $RowSound


enum AnimationState { ROW, ROW_WAIT, STAND, JUMP, JUMP_LAUNCH, JUMP_LAND, SWIM, SWIM_IDLE }


var input_vector = Vector2.ZERO
var row_vector = Vector2.ZERO
var time_since_last_row = ROW_INTERVAL


var steerable:Area2D
var hopping = false
var current_state = AnimationState.STAND

var current_tick_damage = 0
var acorn_count = 0


func _ready() -> void:
	damage_timer.wait_time = DAMAGE_TICKRATE
	damage_timer.timeout.connect(_on_damage)
	steerable_detector.area_entered.connect(_on_steerable_entered)
	steerable_detector.area_exited.connect(_on_steerable_exited)
	boarding_detecor.area_entered.connect(_hop_on)
	acorn_detector.body_entered.connect(_collect_acorn)
	sprite_2d.animation_looped.connect(_on_animation_looped)
	damage_detector.area_entered.connect(_damage_enter)
	damage_detector.area_exited.connect(_damage_exit)
	
	
func drop_acorn() -> void:
	if acorn_count > 0:
		var acorn = AcornScene.instantiate()
		acorn.global_position = global_position + Vector2(randf_range(-DROP_RADIUS, DROP_RADIUS), randf_range(-DROP_RADIUS, DROP_RADIUS))
		
		# Calculate a random direction and strength for the impulse
		var impulse_direction = (acorn.global_position - global_position).normalized()
		var impulse_strength = randf_range(10, 20)
		acorn.apply_impulse(impulse_direction * impulse_strength)
		
		gameobjects.add_child(acorn)
		acorn_count -= 1
		acorn_dropped.emit()
	

func move(input_vector:Vector2) -> void:
	self.input_vector = input_vector.normalized()
	
	if self.input_vector.x != 0:
		sprite_2d.scale.x = 1 if input_vector.x < 0 else -1
		

# special method to follow the player perfectly
# even when they jump between positions
func get_custom_position() -> Vector2:
	return global_position + sprite_2d.offset
		
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
	reparent(objects)
	for shape in swimming_shapes:
		shape.disabled = false
	for shape in boarded_shapes:
		shape.disabled = true
	play_animation(AnimationState.SWIM)
	for i in range(0, acorn_count):
		drop_acorn()
	splash_sound.play()
	
	
func _hop_on_steerable(steerable:Node2D) -> void:
	var camera = get_tree().get_first_node_in_group("Camera") as Camera2D
	# HACK: avoid position smoothing to flicker screen
	reparent(steerable)
	var position_delta = steerable.get_landing_position() - global_position
	sprite_2d.offset = position_delta
	sprite_2d.offset.y *= -1.0
	sprite_2d.offset.x *= -sprite_2d.scale.x
	var move_sprite_to_position_tween = create_tween()
	move_sprite_to_position_tween.tween_property(sprite_2d, "offset", Vector2.ZERO, 0.7)\
	.set_delay(0.4)\
	.finished.connect(func():
				hopping = false
				land_on_pad_sound.pitch_scale = 0.9 + randf_range(0.0, 0.2)
				land_on_pad_sound.play())
	global_position = steerable.get_landing_position()
	for shape in swimming_shapes:
		shape.disabled = true
	for shape in boarded_shapes:
		shape.disabled = false
	time_since_last_row = ROW_INTERVAL
	play_animation(AnimationState.JUMP)
	
	
func _can_row() -> bool:
	return time_since_last_row >= ROW_INTERVAL


func _row() -> void:
	if steerable:
		var force = Vector2(row_vector.x * ROW_STRENGTH, max(0.0, row_vector.y * ROW_STRENGTH))
		steerable.get_parent().apply_central_force(force)
		if current_state != AnimationState.JUMP:
			play_animation(AnimationState.ROW)
			var row_sound_duplicated = row_sound.duplicate()
			row_sound_duplicated.pitch_scale = 0.9 + randf_range(0.0, 0.2)
			row_sound_duplicated.finished.connect(func():
				row_sound_duplicated.queue_free()
				)
			add_child(row_sound_duplicated)
			row_sound_duplicated.play()
		
		
func _collect_acorn(acorn:Node2D) -> void:
	if steerable:
		acorn_count += 1
		acorn_collected.emit(acorn)
		acorn.queue_free()
	
	
func _damage_enter(damageable:Area2D) -> void:
	current_tick_damage += DAMAGE

func _damage_exit(damageable:Area2D) -> void:
	current_tick_damage -= DAMAGE
	
	
func _on_damage() -> void:
	if current_tick_damage > 0:
		if steerable:
			var pad = steerable.get_parent()
			pad.health -= current_tick_damage

	
func play_animation(state: AnimationState):
	current_state = state
	match state:
		AnimationState.ROW:
			sprite_2d.play("Row")
		AnimationState.ROW_WAIT:
			sprite_2d.play("Row-wait")
		AnimationState.STAND:
			sprite_2d.play("Stand")
		AnimationState.JUMP:
			sprite_2d.play("Crouch")
		AnimationState.JUMP_LAUNCH:
			sprite_2d.play("Launch")
		AnimationState.JUMP_LAND:
			sprite_2d.play_backwards("Crouch")
		AnimationState.SWIM:
			sprite_2d.play("Swim")
		AnimationState.SWIM_IDLE:
			sprite_2d.play("Swim-idle")

func _on_animation_looped():
	match current_state:
		AnimationState.ROW:
			play_animation(AnimationState.ROW_WAIT)
		AnimationState.ROW_WAIT:
			if steerable:
				play_animation(AnimationState.STAND)
			else:
				play_animation(AnimationState.SWIM)
		AnimationState.JUMP:
			play_animation(AnimationState.JUMP_LAUNCH)
		AnimationState.JUMP_LAUNCH:
			play_animation(AnimationState.JUMP_LAND)
		AnimationState.JUMP_LAND:
			if steerable:
				play_animation(AnimationState.STAND)
			else:
				play_animation(AnimationState.SWIM)
		AnimationState.SWIM:
			if input_vector != Vector2.ZERO: 
				play_animation(AnimationState.SWIM)
			else:
				play_animation(AnimationState.SWIM_IDLE)
		AnimationState.SWIM_IDLE:
			if input_vector != Vector2.ZERO: 
				play_animation(AnimationState.SWIM)
			else:
				play_animation(AnimationState.SWIM_IDLE)
