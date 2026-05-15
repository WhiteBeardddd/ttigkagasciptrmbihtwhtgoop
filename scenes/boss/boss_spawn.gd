extends Node2D

@export var boss_scene: PackedScene = preload("res://scenes/boss/RatKing.tscn")
@export var spawn_on_ready: bool = false

var boss_instance: Node2D = null
var player: Node2D = null

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	if spawn_on_ready:
		spawn_boss()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "knight" and boss_instance == null:
		spawn_boss()

func spawn_boss() -> void:
	if boss_instance != null:
		return
	boss_instance = boss_scene.instantiate()
	get_tree().current_scene.add_child(boss_instance)
	boss_instance.global_position = global_position
	boss_instance.tree_exiting.connect(_on_boss_defeated)
	print("Boss spawned at: ", boss_instance.global_position)

func _on_boss_defeated() -> void:
	boss_instance = null
	print("Boss defeated!")
