extends Control

var count = 0:
	set(c):
		count = c
		if label:
			label.text = str(count)


@onready var label: Label = $Label
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


func collect_acorn(acorn:Node2D) -> void:
	# animate an acorn that gets collected
	var acorn_copy = animated_sprite_2d.duplicate() as Node2D
	acorn_copy.z_index = 2
	acorn_copy.position = _world_to_screen(acorn.global_position)
	add_child(acorn_copy)
	var target_position = animated_sprite_2d.position - Vector2(8, 10)
	var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(acorn_copy, "global_position", target_position, 1.0)\
	.finished.connect(func(): acorn_copy.queue_free())
	self.count += 1


func _world_to_screen(world_position: Vector2) -> Vector2:
	# Get the current Camera2D node
	var camera = get_viewport().get_camera_2d()
	
	# Get the center of the screen in world coordinates
	var screen_center_world = camera.get_screen_center_position()
	
	# Calculate the offset from the screen center
	var offset = world_position - screen_center_world
	
	# Get the viewport size
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Calculate and return the screen position
	return (viewport_size / 2) + offset
