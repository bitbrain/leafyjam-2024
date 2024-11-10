extends Node2D


const MainMenuScene = preload("res://scenes/main_menu_scene.tscn")

@onready var fade_overlay: FadeOverlay = $CanvasLayer/FadeOverlay


var faded_in = false

func _ready() -> void:
	fade_overlay.visible = true
	fade_overlay.on_complete_fade_in.connect(func(): faded_in = true)


func _process(delta: float) -> void:
	if Input.is_anything_pressed() and faded_in:
		get_tree().change_scene_to_packed(MainMenuScene)
	
