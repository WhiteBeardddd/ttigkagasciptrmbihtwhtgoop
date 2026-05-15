extends Area2D

@export var lines: Array[String] = []
@export var npc_name: String = ""

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var prompt_label: Label = $Label
@onready var final_boss = preload("res://scenes/boss/RatKing.tscn")

var boss_spawned := false

func _ready() -> void:
	prompt_label.hide()
	print("NPC name is: '", npc_name, "'")

func _on_body_entered(body: Node2D) -> void:
	if body.name == "knight":
		if not DialogManager.is_dialog_active:
			sprite.flip_h = body.global_position.x < global_position.x
			var spawn_position = global_position + Vector2(0, -50)
			DialogManager.start_dialog(spawn_position, lines, npc_name)
			await wait_for_dialog_end()
			print("dialog ended, current scene: ", get_tree().current_scene.scene_file_path)
			if get_tree().current_scene.scene_file_path == "res://scenes/maps/FinalMap/Map2.tscn":
				if not boss_spawned:
					print("spawning boss")
					spawn_boss()
					boss_spawned = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "knight":
		prompt_label.hide()

func wait_for_dialog_end() -> void:
	while DialogManager.is_dialog_active:
		await get_tree().process_frame

func spawn_boss() -> void:
	# Stop background music
	var bg_music = get_tree().get_first_node_in_group("background_music")
	if bg_music:
		bg_music.stop()

	var spawn_pos := global_position
	var boss = final_boss.instantiate()
	get_parent().add_child(boss)
	await get_tree().process_frame
	boss.global_position = spawn_pos
	queue_free()
