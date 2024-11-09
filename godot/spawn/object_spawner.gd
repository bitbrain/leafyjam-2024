extends Node2D


@export var min_interval:float = 2.0
@export var max_interval:float = 5.0
@export var spawn_offset:Vector2
@export var spawn_width = 100.0
@export var spawn_limit = 3
@export var spawnables:Array[Spawnable]


@onready var timer: Timer = $Timer
@onready var objects = get_tree().get_first_node_in_group("Objects")


var current_spawn_count = 0
var randomizer:RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	randomizer.seed = Time.get_ticks_usec() + int(get_instance_id())
	timer.wait_time = min_interval + randomizer.randf_range(0.0, max_interval - min_interval)
	timer.timeout.connect(_on_timeout)
	timer.start()
	

func _on_timeout() -> void:
	if current_spawn_count == spawn_limit:
		return
	timer.wait_time = min_interval + randomizer.randf_range(0.0, max_interval - min_interval)
	var spawnable = _get_spawnable_scene()
	var instance = spawnable.scene.instantiate() as Node2D
	instance.position.x = randomizer.randf_range(-spawn_width / 2.0, spawn_width / 2.0)
	instance.global_position = global_position + spawn_offset
	
	if spawnable.preset:
		var children = instance.get_children()
		for child in children:
			child.reparent(objects)
			current_spawn_count += 1
			child.tree_exiting.connect(func(): current_spawn_count -= 1)
		instance.queue_free()
	else:
		objects.add_child(instance)
		current_spawn_count += 1
		instance.tree_exiting.connect(func(): current_spawn_count -= 1)
	

func _get_spawnable_scene() -> Spawnable:
	var total_weight = 0.0
	for spawnable in spawnables:
		total_weight += spawnable.probability
	
	var random_value = randomizer.randf() * total_weight
	
	var cumulative_weight = 0.0
	for spawnable in spawnables:
		cumulative_weight += spawnable.probability
		if random_value <= cumulative_weight:
			return spawnable
	
	return spawnables[0]
