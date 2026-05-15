extends Control

# ─────────────────────────────────────────
#  Main Panel
# ─────────────────────────────────────────
@onready var main_panel:        VBoxContainer = $MainPanel
@onready var btn_play:          Button        = $MainPanel/BtnPlay
@onready var btn_leaderboard:   Button        = $MainPanel/BtnLeaderboard
@onready var btn_quit:          Button        = $MainPanel/BtnQuit

# ─────────────────────────────────────────
#  Play Panel
# ─────────────────────────────────────────
@onready var play_panel:        VBoxContainer = $PlayPanel
@onready var btn_new_user:      Button        = $PlayPanel/BtnNewUser
@onready var btn_continue:      Button        = $PlayPanel/BtnContinue
@onready var profile_list:      ItemList      = $PlayPanel/ProfileList
@onready var btn_back_play:     Button        = $PlayPanel/BtnBack

# ─────────────────────────────────────────
#  Leaderboard Panel
# ─────────────────────────────────────────
@onready var leaderboard_panel: VBoxContainer = $LeaderboardPanel
@onready var leaderboard_list:  ItemList      = $LeaderboardPanel/LeaderboardList
@onready var btn_back_lb:       Button        = $LeaderboardPanel/BtnBack

# ─────────────────────────────────────────
#  Username Dialog
#  Your scene uses VBoxContainer (not VBox) inside UsernameDialog
# ─────────────────────────────────────────
@onready var username_dialog:  Control  = $UsernameDialog
@onready var username_input:   LineEdit = $UsernameDialog/VBoxContainer/UsernameInput
@onready var btn_confirm_name: Button   = $UsernameDialog/VBoxContainer/BtnConfirm
@onready var btn_cancel_name:  Button   = $UsernameDialog/VBoxContainer/BtnCancel

# ─────────────────────────────────────────
func _ready() -> void:
	_show_panel(main_panel)

	# Main panel
	btn_play.pressed.connect(_on_play_pressed)
	btn_leaderboard.pressed.connect(_on_leaderboard_pressed)
	btn_quit.pressed.connect(func(): get_tree().quit())

	# Play panel
	btn_new_user.pressed.connect(_on_new_user_pressed)
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_back_play.pressed.connect(func(): _show_panel(main_panel))

	# Leaderboard panel
	btn_back_lb.pressed.connect(func(): _show_panel(main_panel))

	# Username dialog
	btn_confirm_name.pressed.connect(_on_confirm_name)
	btn_cancel_name.pressed.connect(func(): username_dialog.hide())

# ─────────────────────────────────────────
#  Panel switching
# ─────────────────────────────────────────
func _show_panel(panel: Control) -> void:
	main_panel.visible        = (panel == main_panel)
	play_panel.visible        = (panel == play_panel)
	leaderboard_panel.visible = (panel == leaderboard_panel)
	username_dialog.hide()

# ─────────────────────────────────────────
#  Main panel handlers
# ─────────────────────────────────────────
func _on_play_pressed() -> void:
	_refresh_profile_list()
	_show_panel(play_panel)

func _on_leaderboard_pressed() -> void:
	_refresh_leaderboard()
	_show_panel(leaderboard_panel)

# ─────────────────────────────────────────
#  Play panel handlers
# ─────────────────────────────────────────

func _on_new_user_pressed() -> void:
	username_input.text = ""
	username_dialog.show()

func _refresh_profile_list() -> void:
	profile_list.clear()
	for uname in GameManager.get_all_profiles():
		# Peek at the save file without changing the active profile
		var path: String = GameManager.save_dir + uname + ".json"
		var lives_left := 3  # default if unreadable
		if FileAccess.file_exists(path):
			var f := FileAccess.open(path, FileAccess.READ)
			if f:
				var parsed: Variant = JSON.parse_string(f.get_as_text())
				f.close()
				if typeof(parsed) == TYPE_DICTIONARY:
					lives_left = parsed.get("lives", 3)

		if lives_left > 0:
			profile_list.add_item(uname)
		# Profiles with 0 lives appear in the leaderboard only — not here

func _on_continue_pressed() -> void:
	var selected := profile_list.get_selected_items()
	if selected.is_empty():
		return
	var uname: String = profile_list.get_item_text(selected[0])
	if GameManager.load_profile(uname):
		GameManager.switch_map(GameManager.current_map)
	else:
		push_warning("MainMenu: could not load profile — " + uname)

# ─────────────────────────────────────────
#  Username dialog handlers
# ─────────────────────────────────────────
func _on_confirm_name() -> void:
	var uname := username_input.text.strip_edges()
	if uname == "":
		return
	if GameManager.profile_exists(uname):
		push_warning("MainMenu: username already taken — " + uname)
		return
	GameManager.new_profile(uname)
	username_dialog.hide()
	GameManager.switch_map("res://scenes/maps/FinalMap/Map1.tscn")

# ─────────────────────────────────────────
#  Leaderboard handlers
# ─────────────────────────────────────────
func _refresh_leaderboard() -> void:
	leaderboard_list.clear()
	var board := GameManager.get_leaderboard()	
	if board.is_empty():
		leaderboard_list.add_item("No records yet.")
		return
	for entry in board:
		var uname: String       = entry.get("username", "?")
		var map: String         = entry.get("map",      "?")
		var map_display: String = map.get_file().trim_suffix(".tscn")
		leaderboard_list.add_item("%s  —  %s" % [uname, map_display])
