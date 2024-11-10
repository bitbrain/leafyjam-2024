extends Node2D


const GameOverScene = preload("res://scenes/game_over_scene.tscn")


@onready var fade_overlay = %FadeOverlay
@onready var pause_overlay = %PauseOverlay
@onready var acorn_count: Control = %AcornCount
@onready var player: Player = %Player


func _ready() -> void:
	fade_overlay.visible = true
	
	if SaveGame.has_save():
		SaveGame.load_game(get_tree())
	
	pause_overlay.game_exited.connect(_save_game)
	player.acorn_collected.connect(acorn_count.collect_acorn)
	player.acorn_dropped.connect(acorn_count.drop_acorn)
	acorn_count.game_won.connect(_on_game_won)
	fade_overlay.on_complete_fade_out.connect(_game_over_screen)

func _input(event) -> void:
	if event.is_action_pressed("pause") and not pause_overlay.visible:
		get_viewport().set_input_as_handled()
		get_tree().paused = true
		pause_overlay.grab_button_focus()
		pause_overlay.visible = true
		
func _save_game() -> void:
	SaveGame.save_game(get_tree())
	

func _on_game_won() -> void:
	get_tree().paused = true
	fade_overlay.fade_out()


func _game_over_screen() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_packed(GameOverScene)
