class_name Knight extends CharacterBody2D

var hp: int
var _is_dead: bool = false

@export var speed:            float = 180.0
@export var jump_velocity:    float = -400.0
@export var gravity:          float = 900.0
@export var dash_speed:       float = 400.0
@export var roll_speed:       float = 300.0
@export var wall_slide_speed: float = 60.0
@export var wall_climb_speed: float = -120.0

const COMBO_WINDOW := 0.6
var attack_combo   := 0
var combo_timer    := 0.0

@onready var anim:              AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_controller                  = $AttackController
@onready var health_bar                         = $HUD/HealthBar

# HUD nodes
@onready var hud_username:   Label          = $HUD/Username
@onready var hud_life_label: Label          = $HUD/LifeLabel
@onready var hud_life_value: Label          = $HUD/LifeValue

# Game Over Panel nodes
@onready var game_over_panel: PanelContainer = $HUD/GameOverPanel
@onready var go_map_label:    Label          = $HUD/GameOverPanel/VBoxContainer/MapLabel
@onready var go_btn_menu:     Button         = $HUD/GameOverPanel/VBoxContainer/BtnMainMenu
@onready var go_btn_quit:     Button         = $HUD/GameOverPanel/VBoxContainer/BtnQuit

# Pause Panel nodes
@onready var pause_panel:  PanelContainer = $HUD/PausePanel
@onready var p_btn_resume: Button         = $HUD/PausePanel/VBoxContainer/BtnResume
@onready var p_btn_save:   Button         = $HUD/PausePanel/VBoxContainer/BtnSave
@onready var p_btn_quit:   Button         = $HUD/PausePanel/VBoxContainer/BtnQuit

# ── Heart sprites (optional) ──────────────────────────────────────────────────
@export var heart_full_texture:  Texture2D
@export var heart_empty_texture: Texture2D
var _heart_nodes: Array = []

# ─────────────────────────────────────────
func _ready() -> void:
	_is_dead = false
	hp       = GameManager.player_hp

	anim.animation_finished.connect(_on_anim_finished)
	$Hurtbox.damaged.connect(_on_damaged)
	GameManager.stats_updated.connect(_on_stats_updated)
	GameManager.lives_updated.connect(_on_lives_updated)
	GameManager.game_over.connect(_on_game_over)

	# Health bar
	health_bar.init_health(GameManager.player_max_hp)
	health_bar.health = GameManager.player_hp

	# Username
	if hud_username:
		hud_username.text = GameManager.username

	# Lives
	_refresh_lives_display()

	# Heart sprites
	_heart_nodes.clear()
	for i in range(1, 4):
		var node = get_node_or_null("HUD/Heart%d" % i)
		if node:
			_heart_nodes.append(node)

	# Game Over panel
	game_over_panel.visible = false
	# Pause panel
	pause_panel.visible = false
	pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	p_btn_resume.pressed.connect(_on_pause_resume)
	p_btn_save.pressed.connect(_on_pause_save)
	p_btn_quit.pressed.connect(_on_pause_quit)
	go_btn_menu.pressed.connect(_on_go_btn_menu_pressed)
	go_btn_quit.pressed.connect(func(): get_tree().quit())

	# Spawn position
	var spawn = get_tree().current_scene.get_node_or_null(GameManager.spawn_point_name)
	if spawn:
		global_position = spawn.global_position

# ─────────────────────────────────────────
#  HUD refresh helpers
# ─────────────────────────────────────────
func _refresh_lives_display() -> void:
	if hud_life_value:
		hud_life_value.text = str(GameManager.lives)

	if _heart_nodes.is_empty() or not heart_full_texture or not heart_empty_texture:
		return
	for i in range(_heart_nodes.size()):
		var heart: TextureRect = _heart_nodes[i]
		if i < GameManager.lives:
			heart.texture = heart_full_texture
		else:
			heart.texture = heart_empty_texture

func _on_stats_updated() -> void:
	hp = GameManager.player_hp
	health_bar.health = hp

func _on_lives_updated() -> void:
	_refresh_lives_display()

# ─────────────────────────────────────────
#  Game Over
# ─────────────────────────────────────────
func _on_game_over() -> void:
	game_over_panel.visible = true
	var map_display: String = GameManager.current_map.get_file().trim_suffix(".tscn")
	go_map_label.text = "Reached: %s" % map_display
	get_tree().paused = true
	game_over_panel.process_mode = Node.PROCESS_MODE_ALWAYS

func _on_go_btn_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

# ─────────────────────────────────────────
#  Scene exit
# ─────────────────────────────────────────
func _exit_tree() -> void:
	if not _is_dead:
		GameManager.player_hp = hp

# ─────────────────────────────────────────
#  Animation callbacks
# ─────────────────────────────────────────
func _on_anim_finished() -> void:
	match anim.animation:
		"attack1":
			if attack_combo == 2:
				attack_combo = 0
				$StateMachine._on_state_finished("Attack2")
			else:
				attack_combo = 0
				$StateMachine._on_state_finished("Idle")
		"attack2", "attack3", "crouch_attack":
			attack_combo = 0
			$StateMachine._on_state_finished("Idle")
		"roll":
			$StateMachine._on_state_finished("Idle")
		"slide":
			$StateMachine._on_state_finished("Idle")
		"hit":
			if not _is_dead:
				$StateMachine._on_state_finished("Idle")
		"dash":
			$StateMachine._on_state_finished("Idle")
		"death":
			GameManager.handle_player_death()

# ─────────────────────────────────────────
#  Movement helpers
# ─────────────────────────────────────────
func play_anim(anim_name: String) -> void:
	if anim.animation != anim_name:
		anim.play(anim_name)

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

func apply_horizontal(dir: float) -> void:
	if dir != 0.0:
		velocity.x = dir * speed
		anim.flip_h = dir < 0.0
		attack_controller.facing_right = dir > 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)

# ─────────────────────────────────────────
#  Combat
# ─────────────────────────────────────────

# Called by Hurtbox.gd signal — Area2D overlap path
func _on_damaged(amount: int, knockback: Vector2) -> void:
	print("Knight Hurtbox signal received! Amount: ", amount)  # debug — remove later
	if _is_dead:
		return
	take_hit(amount)

# Called directly by bullets that use body_entered / has_method("take_damage")
# This bridges bullets that target the knight body instead of the Hurtbox Area2D
func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	print("Knight take_damage called! Amount: ", amount)  # debug — remove later
	if _is_dead:
		return
	take_hit(amount)

func take_hit(amount: int = 10) -> void:
	print("take_hit — HP before: ", GameManager.player_hp, " | damage: ", amount)  # debug
	if _is_dead:
		return
	GameManager.take_damage(amount)
	hp = GameManager.player_hp
	print("take_hit — HP after: ", hp)  # debug — remove later
	if hp <= 0:
		die()
	else:
		$StateMachine._on_state_finished("Hit")

func die() -> void:
	if _is_dead:
		return
	_is_dead = true
	if has_node("Hurtbox"):
		$Hurtbox.set_deferred("monitoring", false)
	$StateMachine._on_state_finished("Death")

func spawn_attack_hitbox(attack_name: String) -> void:
	attack_controller.spawn_hitbox(attack_name)

# ─────────────────────────────────────────
#  Pause
# ─────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if game_over_panel.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			_on_pause_resume()
		else:
			_pause_game()

func _pause_game() -> void:
	get_tree().paused = true
	pause_panel.visible = true

func _on_pause_resume() -> void:
	get_tree().paused = false
	pause_panel.visible = false

func _on_pause_save() -> void:
	GameManager.save_profile()
	p_btn_save.text = "Saved!"
	await get_tree().create_timer(1.2).timeout
	p_btn_save.text = "Save"

func _on_pause_quit() -> void:
	GameManager.save_profile()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
