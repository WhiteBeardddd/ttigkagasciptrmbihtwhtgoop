extends Node

# ─────────────────────────────────────────
#  Scene reference
# ─────────────────────────────────────────
const KNIGHT_SCENE = preload("res://scenes/characters/knight.tscn")

# ─────────────────────────────────────────
#  Player stats (runtime)
# ─────────────────────────────────────────
var player_hp:      int = 100
var player_max_hp:  int = 100
var player_score:   int = 0
var inventory:      Array = []
var lives:          int = 3

# ─────────────────────────────────────────
#  Map / spawn tracking
# ─────────────────────────────────────────
var current_map:      String = "res://scenes/maps/FinalMap/Map1.tscn"
var spawn_point_name: String = "SpawnPoint"

# ─────────────────────────────────────────
#  Profile / save data
# ─────────────────────────────────────────
var username:         String = ""
var save_dir:         String = "user://saves/"
var leaderboard_path: String = "user://saves/leaderboard.json"

signal stats_updated
signal lives_updated
signal game_over

# ─────────────────────────────────────────
#  Lifecycle
# ─────────────────────────────────────────
func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(save_dir)

# ─────────────────────────────────────────
#  Stats helpers
# ─────────────────────────────────────────
func reset_stats() -> void:
	player_hp        = player_max_hp   # restore to full, NOT hard-coded 100
	player_score     = 0
	inventory        = []
	spawn_point_name = "SpawnPoint"
	# NOTE: current_map and lives are intentionally NOT reset here.
	# current_map is only reset when the player reaches game over.
	# lives       is only reset when starting a new game.

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

# ─────────────────────────────────────────
#  Lives & respawn
# ─────────────────────────────────────────

# Called by Knight.die() instead of directly calling reset_stats + switch_map.
func handle_player_death() -> void:
	if lives <= 0:
		# Already at game over — don't re-trigger
		return

	lives -= 1
	emit_signal("lives_updated")

	if lives <= 0:
		lives = 0
		save_profile()
		update_leaderboard()
		emit_signal("game_over")
	else:
		var respawn_map = current_map
		player_hp = player_max_hp
		save_profile()
		get_tree().change_scene_to_file(respawn_map)
		
# ─────────────────────────────────────────
#  Spawning
# ─────────────────────────────────────────
func spawn_knight(scene: Node) -> void:
	for child in scene.get_children():
		if child is Knight or child.name == "Knight":
			return

	var knight = KNIGHT_SCENE.instantiate()
	scene.add_child(knight)

	var spawn = scene.get_node_or_null(spawn_point_name)
	if spawn:
		knight.global_position = spawn.global_position

	var level_camera = scene.get_node_or_null("LevelCamera")
	if level_camera:
		level_camera.reparent(knight)
		level_camera.position = Vector2.ZERO
		level_camera.make_current()

# ─────────────────────────────────────────
#  Map switching
# ─────────────────────────────────────────
func switch_map(map_path: String, spawn_name: String = "SpawnPoint") -> void:
	if not FileAccess.file_exists(map_path):
		push_warning("GameManager.switch_map: file not found — " + map_path)
		return
	current_map      = map_path   # always update BEFORE changing scene
	spawn_point_name = spawn_name
	save_profile()
	update_leaderboard()               # persist current map on every transition
	get_tree().change_scene_to_file(map_path)

# ─────────────────────────────────────────
#  Save / Load  (per-user JSON file)
# ─────────────────────────────────────────
func _save_path() -> String:
	return save_dir + username + ".json"

func save_profile() -> void:
	if username == "":
		return
	var data := {
		"username":    username,
		"current_map": current_map,
		"lives":       lives,
		"player_hp":   player_hp,
		"player_max_hp": player_max_hp,
		"player_score": player_score,
	}
	var f := FileAccess.open(_save_path(), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()

func load_profile(uname: String) -> bool:
	username = uname
	var path := _save_path()
	if not FileAccess.file_exists(path):
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		return false
	var raw    := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var data: Dictionary = parsed as Dictionary
	username      = data.get("username",      uname)
	current_map   = data.get("current_map",   "res://scenes/maps/FinalMap/Map1.tscn")
	lives         = data.get("lives",         3)
	player_hp     = data.get("player_hp",     100)
	player_max_hp = data.get("player_max_hp", 100)
	player_score  = data.get("player_score",  0)
	return true

func new_profile(uname: String) -> void:
	username      = uname
	current_map   = "res://scenes/maps/FinalMap/Map1.tscn"
	lives         = 3
	player_hp     = 100
	player_max_hp = 100
	player_score  = 0
	inventory     = []
	save_profile()

func profile_exists(uname: String) -> bool:
	return FileAccess.file_exists(save_dir + uname + ".json")

# Returns a list of all saved usernames
func get_all_profiles() -> Array:
	var names: Array = []
	var dir := DirAccess.open(save_dir)
	if not dir:
		return names
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.ends_with(".json") and f != "leaderboard.json":
			names.append(f.trim_suffix(".json"))
		f = dir.get_next()
	dir.list_dir_end()
	return names

# ─────────────────────────────────────────
#  Leaderboard  (local JSON)
# ─────────────────────────────────────────

# Leaderboard entry shape: { "username": String, "map": String, "score": int }

func update_leaderboard() -> void:
	print("update_leaderboard called — username: '", username, "' map: '", current_map, "'")
	if username == "":
		return
	var board := _load_leaderboard()
	# Find existing entry for this user
	var found := false
	for entry in board:
		if entry.get("username", "") == username:
			# Only update if this map is further (or score is higher)
			entry["map"]   = current_map
			entry["score"] = player_score
			found = true
			break
	if not found:
		board.append({
			"username": username,
			"map":      current_map,
			"score":    player_score,
		})
	_save_leaderboard(board)

func get_leaderboard() -> Array:
	return _load_leaderboard()

func _load_leaderboard() -> Array:
	if not FileAccess.file_exists(leaderboard_path):
		return []
	var f := FileAccess.open(leaderboard_path, FileAccess.READ)
	if not f:
		return []
	var raw    := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) == TYPE_ARRAY:
		return parsed as Array
	return []

func _save_leaderboard(board: Array) -> void:
	var f := FileAccess.open(leaderboard_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(board, "\t"))
		f.close()
