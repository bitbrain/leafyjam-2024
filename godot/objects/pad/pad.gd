extends RigidBody2D


signal sunk
signal sinking


@export var sinking_damage = 1


@onready var sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var steerable_area: Area2D = $SteerableArea
@onready var sinking_timer: Timer = $SinkingTimer
@onready var spot: Marker2D = $Spot
@onready var crest_animated_sprite_2d: AnimatedSprite2D = %CrestAnimatedSprite2D


var is_sinking = false
var touched = false
var immune_to_sinking = true
var health = 100.0:
	set(h):
		health = h
		if health < 0:
			health = 0
		if health > 100:
			health = 100
		# update animation here based on healh
		var animation_names = sprite_2d.sprite_frames.get_animation_names()
		var index = _remap_rangef(health, 20, 100, animation_names.size() - 1, 1)
		sprite_2d.play(animation_names[index])
		
		if not is_sinking and health == 0:
			_sink()


func _ready() -> void:
	steerable_area.area_entered.connect(
		func(area):
			immune_to_sinking = false
			touched = true
	)
	steerable_area.area_exited.connect(func(area): immune_to_sinking = true)
	sinking_timer.timeout.connect(func():
		if touched and not is_sinking:
			health -= sinking_damage
		)
		
		
func get_landing_position() -> Vector2:
	return spot.global_position
		
		
func _sink() -> void:
	is_sinking = true
	sinking.emit()
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(sprite_2d, "modulate:a", 0.0, 0.5).finished.connect(_finish_sinking)
	
	
func _finish_sinking() -> void:
	sunk.emit()
	queue_free()
	
	
func _remap_rangef(input:float, minInput:float, maxInput:float, minOutput:int, maxOutput:int):
	return int(float(input - minInput) / float(maxInput - minInput) * float(maxOutput - minOutput) + minOutput)
