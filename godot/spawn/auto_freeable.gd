# auto-frees objects
extends Node2D


@onready var visible_on_screen_notifier_2d: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D


func _ready() -> void:
	visible_on_screen_notifier_2d.screen_exited.connect(_on_screen_exited)


func _on_screen_exited() -> void:
	get_parent().queue_free()
