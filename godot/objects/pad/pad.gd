extends RigidBody2D


signal sunk
signal sinking


@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var steerable_area: Area2D = $SteerableArea


var is_sinking = false
var immune_to_sinking = true


func _ready() -> void:
	steerable_area.area_entered.connect(func(): immune_to_sinking = false)
	steerable_area.area_exited.connect(func(): immune_to_sinking = true)


func _process(delta: float) -> void:
	if immune_to_sinking:
		return
	if linear_velocity.length() <= 0.001 and not is_sinking:
		is_sinking = true
		_sink()
		
		
func _sink() -> void:
	sinking.emit()
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(sprite_2d, "modulate:a", 0.0, 2.0).finished.connect(_finish_sinking)
	
	
func _finish_sinking() -> void:
	sunk.emit()
	queue_free()
