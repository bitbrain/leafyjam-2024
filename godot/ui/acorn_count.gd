extends Control


var count = 0:
	set(c):
		count = c
		if label:
			label.text = str(count)


@onready var label: Label = $Label


func collect_acorn(from_global_position:Vector2) -> void:
	self.count += 1
