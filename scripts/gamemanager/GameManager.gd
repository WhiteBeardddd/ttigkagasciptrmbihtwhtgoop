extends Node

const KNIGHT_SCENE = preload("res://scenes/characters/knight.tscn")

var player_hp: int = 100
var player_max_hp: int = 100
var player_score: int = 0
var inventory: Array = []
var current_map: String = "res://scenes/maps/FinalMap/Map1.tscn"
var spawn_point_name: String = "SpawnPoint"

signal stats_updated

func _ready() -> void:
	reset_stats()

func reset_stats() -> void:
	player_hp        = 100
	player_max_hp    = 100
	player_score     = 0
	inventory        = []
	spawn_point_name = "SpawnPoint"

func set_hp(new_hp: int) -> void:
	player_hp = clamp(new_hp, 0, player_max_hp)
	emit_signal("stats_updated")

func take_damage(amount: int) -> void:
	set_hp(player_hp - amount)

func heal(amount: int) -> void:
	set_hp(player_hp + amount)

func add_score(points: int) -> void:
	player_score += points
	emit_signal("stats_updated")

func spawn_knight(scene: Node) -> void:
	# Check if knight already exists to prevent duplicate spawns
	for child in scene.get_children():
		if child is Knight or child.name == "Knight":
			return
			
	var knight = KNIGHT_SCENE.instantiate()
	scene.add_child(knight)
	
	# Handle positioning
	var spawn = scene.get_node_or_null(spawn_point_name)
	if spawn:
		knight.global_position = spawn.global_position

	# --- CAMERA REPARENTING LOGIC ---
	var level_camera = scene.get_node_or_null("LevelCamera")
	if level_camera:
		# Move the camera from the Map scene to the Knight
		level_camera.reparent(knight)
		
		# Reset its position so it is perfectly centered on the Knight
		level_camera.position = Vector2.ZERO
		
		# Ensure this camera is the active one rendering to the screen
		level_camera.make_current()

func switch_map(map_path: String, spawn_name: String = "SpawnPoint") -> void:
	if not FileAccess.file_exists(map_path):
		return
	current_map = map_path
	spawn_point_name = spawn_name
	get_tree().change_scene_to_file(map_path)
