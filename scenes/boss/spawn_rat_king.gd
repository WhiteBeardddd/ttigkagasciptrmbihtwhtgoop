extends Area2D

@onready var mini_boss_scene = preload("res://scenes/boss/RatKing.tscn")
var is_spawned : bool = false

signal boss_defeated

func _on_body_entered(body: Node) -> void:
	if body.name == "knight" and not is_spawned:
		is_spawned = true
		var boss = mini_boss_scene.instantiate()
		boss.position = global_position  # set position BEFORE adding to tree
		get_parent().add_child(boss)
		boss.tree_exiting.connect(_on_boss_defeated)

func _on_boss_defeated() -> void:
	print("MiniBoss defeated!")
	boss_defeated.emit()
