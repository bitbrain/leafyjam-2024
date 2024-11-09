# auto-frees objects
extends Node2D


@onready var visible_on_screen_notifier_2d: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D


var visible_once = false


func _ready() -> void:
	visible_on_screen_notifier_2d.screen_entered.connect(_on_screen_entered)
	visible_on_screen_notifier_2d.screen_exited.connect(_on_screen_exited)
		
		
func _on_screen_entered() -> void:
	visible_once = true
	
	
func _on_screen_exited() -> void:
	if visible_once:
		get_parent().queue_free()
