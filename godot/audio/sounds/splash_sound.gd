extends Node2D


func play() -> void:
	var random_child = get_child(randi_range(0, get_child_count() - 1))
	random_child.play()
