extends Node2D


const Pad = preload("res://pad/pad.tscn")


@export var interval:float = 2.0:
	set(i):
		interval = i
		if timer:
			timer.wait_time = interval
@export var spawn_offset:Vector2


@onready var timer: Timer = $Timer
@onready var objects = get_tree().get_first_node_in_group("Objects")


func _ready() -> void:
	timer.wait_time = interval
	timer.timeout.connect(_on_timeout)
	

func _on_timeout() -> void:
	var pad = Pad.instantiate()
	objects.add_child(pad)
	
	pad.position.x = randf_range(-100, 100)
	pad.global_position = global_position + spawn_offset
	
