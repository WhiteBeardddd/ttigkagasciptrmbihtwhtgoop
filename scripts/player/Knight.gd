class_name Knight extends CharacterBody2D

var hp: int
var _is_dead: bool = false

@export var speed            := 180.0
@export var jump_velocity    := -400.0
@export var gravity          := 900.0
@export var dash_speed       := 400.0
@export var roll_speed       := 300.0
@export var wall_slide_speed := 60.0
@export var wall_climb_speed := -120.0

const COMBO_WINDOW := 0.6
var attack_combo   := 0
var combo_timer    := 0.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_controller = $AttackController
@onready var health_bar = $HUD/HealthBar

func _ready() -> void:
<<<<<<< HEAD
=======

>>>>>>> 7aa13764d7842d12de0c645b043480ecf8990607
	_is_dead = false
	hp = GameManager.player_hp
	anim.animation_finished.connect(_on_anim_finished)
	$Hurtbox.damaged.connect(_on_damaged)

	# Initialize health bar — restores correct HP across maps
	health_bar.init_health(GameManager.player_max_hp)
	health_bar.health = GameManager.player_hp

	var spawn = get_tree().current_scene.get_node_or_null(GameManager.spawn_point_name)
	if spawn:
		global_position = spawn.global_position

func _on_stats_updated() -> void:
	hp = GameManager.player_hp

func _exit_tree() -> void:
<<<<<<< HEAD
	GameManager.player_hp = hp
=======
	# Only save HP if knight is alive — don't save 0 on death
	if not _is_dead:
		GameManager.player_hp = hp

	anim.animation_finished.connect(_on_anim_finished)

>>>>>>> 7aa13764d7842d12de0c645b043480ecf8990607

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
			GameManager.reset_stats()
			GameManager.switch_map(GameManager.current_map)

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

func _on_damaged(amount: int, knockback: Vector2) -> void:
	if _is_dead:
		return
	take_hit(amount)

<<<<<<< HEAD
=======

>>>>>>> 7aa13764d7842d12de0c645b043480ecf8990607
func take_hit(amount: int = 10) -> void:
	if _is_dead:
		return
	GameManager.take_damage(amount)
	hp = GameManager.player_hp
<<<<<<< HEAD
=======

# --- External API ---

>>>>>>> 7aa13764d7842d12de0c645b043480ecf8990607

	# Update health bar when taking damage
	health_bar.health = hp

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
