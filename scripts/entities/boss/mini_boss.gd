extends CharacterBody2D

# ═══════════════════════════════════════════════════════════
#  MINI BOSS — AI Script
#  Node tree expected:
#    MiniBoss (CharacterBody2D)  ← this script
#    ├── HUD
#    │   └── HealthBar (ProgressBar)
#    ├── CollisionShape2D
#    ├── Weakpoint (Area2D + Hurtbox.gd)
#    │   └── CollisionShape2D
#    ├── Eye
#    │   ├── EyeBall
#    │   └── Body
#    ├── Attack1-FromEye (Area2D)
#    │   ├── Collision
#    │   └── AttackDesign (AnimatedSprite2D)
#    └── Attack2-SpawnObjects (Area2D)
#        ├── Collision
#        └── AttackDesign (AnimatedSprite2D)
# ═══════════════════════════════════════════════════════════

# ── Node References ──────────────────────────────────────
@onready var weakpoint    : Area2D      = $Weakpoint
@onready var attack1_root : Node2D      = $"Attack1-FromEye"
@onready var attack2_root : Node2D      = $"Attack2-SpawnObjects"
@onready var health_bar   : ProgressBar = $HUD/HealthBar
@onready var eyeball              : Node2D           = $Weakpoint/Eye/EyeBall
@onready var attack1_design       : AnimatedSprite2D = $"Attack1-FromEye/AttackDesign"
@onready var attack2_design       : AnimatedSprite2D = $"Attack2-SpawnObjects/AttackDesign"

# ── Shooters ─────────────────────────────────────────────
var _shooter1 : MiniBossProjectileShooter = null
var _shooter2 : MiniBossProjectileShooter = null

# ── Eyeball Tracking ─────────────────────────────────────
const EYEBALL_DEFAULT : Vector2 = Vector2(2.042, -9.167)
const EYEBALL_RADIUS  : float   = 11.0

# ── Health ───────────────────────────────────────────────
@export var max_hp  : int  = 200
var current_hp      : int  = 200
var is_dead         : bool = false

# ── Knockback ────────────────────────────────────────────
var _is_staggered : bool = false

# ── Movement ─────────────────────────────────────────────
@export var base_speed    : float = 200.0
@export var surge_speed   : float = 420.0
@export var acceleration  : float = 5.0
@export var bob_amplitude : float = 10.0
@export var bob_speed     : float = 2.0

# ── Distances ────────────────────────────────────────────
@export var hover_height    : float = 200.0
@export var close_distance  : float = 80.0
@export var fly_up_distance : float = 320.0
@export var side_dash_range : float = 280.0

# ── Phase Durations ──────────────────────────────────────
@export var fly_phase_duration   : float = 6.0
@export var close_phase_duration : float = 3.5

# ── Action Intervals ─────────────────────────────────────
@export var fly_action_interval_min   : float = 0.8
@export var fly_action_interval_max   : float = 1.8
@export var close_action_interval_min : float = 0.4
@export var close_action_interval_max : float = 1.0

# ── Projectiles ──────────────────────────────────────────
@export var attack1_interval : float = 3.0
@export var attack2_interval : float = 5.0
@export var attack2_spread   : float = 120.0

# ── Enums ────────────────────────────────────────────────
enum MainPhase { FLYING, CLOSE }
enum Action    { HOVER, FLY_UP, SIDE_DASH, SURGE, SWOOP_CLOSE, CIRCLE_PLAYER }

# ── Internal State ───────────────────────────────────────
var player            : Node2D  = null
var _main_phase                 = MainPhase.FLYING
var _main_phase_timer : float   = 0.0
var _action                     = Action.HOVER
var _action_timer     : float   = 0.0
var _action_interval  : float   = 1.5
var _bob_timer        : float   = 0.0
var _target_pos       : Vector2 = Vector2.ZERO
var _drift_offset     : Vector2 = Vector2.ZERO
var _circle_angle     : float   = 0.0
var _attack1_timer    : float   = 0.0
var _attack2_timer    : float   = 0.0

# ════════════════════════════════════════════════════════
#  READY
# ════════════════════════════════════════════════════════
func _ready() -> void:
	current_hp     = max_hp
	# init_health sets max_value, value, and DamageBar — don't set value again after
	health_bar.init_health(max_hp)

	_attack1_timer = attack1_interval
	_attack2_timer = attack2_interval * 0.5

	weakpoint.damaged.connect(_on_weakpoint_damaged)

	_shooter1 = MiniBossProjectileShooter.new()
	_shooter2 = MiniBossProjectileShooter.new()
	add_child(_shooter1)
	add_child(_shooter2)
	_shooter1.bullet_template     = attack1_design
	_shooter1.rotate_to_direction = false
	_shooter1.bullet_damage       = 10    # Attack1 damage
	_shooter1.hitbox_delay         = 0.15  # short delay — bullet spawns far from player
	_shooter2.bullet_template     = attack2_design
	_shooter2.rotate_to_direction = true
	_shooter2.bullet_damage       = 15    # Attack2 spread damage
	_shooter2.hitbox_delay         = 0.35  # longer delay — bullets spawn near player

	_find_player()

# ════════════════════════════════════════════════════════
#  FIND PLAYER
# ════════════════════════════════════════════════════════
func _find_player() -> void:
	player = get_tree().current_scene.get_node_or_null("knight")
	if player == null:
		await get_tree().process_frame
		_find_player()
	else:
		if _shooter1 != null:
			_shooter1.player = player
		if _shooter2 != null:
			_shooter2.player = player
		_enter_flying_phase()

# ════════════════════════════════════════════════════════
#  PHYSICS PROCESS
# ════════════════════════════════════════════════════════
func _physics_process(delta: float) -> void:
	if is_dead or player == null:
		return

	if _is_staggered:
		velocity = velocity.move_toward(Vector2.ZERO, 800.0 * delta)
		move_and_slide()
		return

	_bob_timer        += delta
	_action_timer     += delta
	_main_phase_timer += delta

	_tick_phase()
	_tick_action()
	_execute_action(delta)
	_handle_attack_timers(delta)
	move_and_slide()

func _process(_delta: float) -> void:
	_track_eyeball()

# ════════════════════════════════════════════════════════
#  EYEBALL TRACKING
# ════════════════════════════════════════════════════════
func _track_eyeball() -> void:
	if player == null or not is_instance_valid(eyeball):
		return
	var dir    := (player.global_position - global_position).normalized()
	var target := EYEBALL_DEFAULT + dir * EYEBALL_RADIUS
	eyeball.position = eyeball.position.lerp(target, 0.15)

# ════════════════════════════════════════════════════════
#  PHASE LOGIC
# ════════════════════════════════════════════════════════
func _tick_phase() -> void:
	match _main_phase:
		MainPhase.FLYING:
			if _main_phase_timer >= fly_phase_duration:
				_enter_close_phase()
		MainPhase.CLOSE:
			if _main_phase_timer >= close_phase_duration:
				_enter_flying_phase()

func _enter_flying_phase() -> void:
	_main_phase       = MainPhase.FLYING
	_main_phase_timer = 0.0
	_action_timer     = 0.0
	_pick_action()

func _enter_close_phase() -> void:
	_main_phase       = MainPhase.CLOSE
	_main_phase_timer = 0.0
	_action_timer     = 0.0
	_pick_action()

# ════════════════════════════════════════════════════════
#  ACTION LOGIC
# ════════════════════════════════════════════════════════
func _tick_action() -> void:
	if _action_timer >= _action_interval:
		_action_timer = 0.0
		_pick_action()

func _pick_action() -> void:
	match _main_phase:
		MainPhase.FLYING:
			_action_interval = randf_range(fly_action_interval_min, fly_action_interval_max)
			var roll := randf()
			if roll < 0.40:
				_action       = Action.FLY_UP
				_drift_offset = Vector2(randf_range(-200.0, 200.0), 0.0)
			elif roll < 0.70:
				_action = Action.SIDE_DASH
				var side := 1.0 if randf() > 0.5 else -1.0
				_drift_offset = Vector2(
					side * randf_range(side_dash_range * 0.5, side_dash_range),
					-randf_range(180.0, 300.0)
				)
			elif roll < 0.90:
				_action     = Action.SURGE
				_target_pos = player.global_position + Vector2(
					randf_range(-300.0, 300.0),
					-randf_range(160.0, 380.0)
				)
			else:
				_action       = Action.HOVER
				_drift_offset = Vector2(
					randf_range(-150.0, 150.0),
					-randf_range(180.0, 280.0)
				)

		MainPhase.CLOSE:
			_action_interval = randf_range(close_action_interval_min, close_action_interval_max)
			var roll := randf()
			if roll < 0.45:
				_action       = Action.SWOOP_CLOSE
				_drift_offset = Vector2(randf_range(-80.0, 80.0), 0.0)
			elif roll < 0.75:
				_action       = Action.CIRCLE_PLAYER
				_circle_angle = randf_range(0.0, TAU)
			else:
				_action = Action.SIDE_DASH
				var side := 1.0 if randf() > 0.5 else -1.0
				_drift_offset = Vector2(side * randf_range(50.0, 120.0), -close_distance)

func _execute_action(delta: float) -> void:
	match _action:
		Action.HOVER:
			var target := player.global_position \
				+ Vector2(_drift_offset.x, -hover_height + _drift_offset.y) \
				+ Vector2(0.0, sin(_bob_timer * bob_speed) * bob_amplitude)
			_move_toward(target, base_speed, delta)

		Action.FLY_UP:
			var target := player.global_position + Vector2(_drift_offset.x, -fly_up_distance)
			_move_toward(target, surge_speed * 0.85, delta)

		Action.SIDE_DASH:
			_move_toward(player.global_position + _drift_offset, surge_speed, delta)

		Action.SURGE:
			_move_toward(_target_pos, surge_speed * 1.1, delta)

		Action.SWOOP_CLOSE:
			var target := player.global_position + Vector2(_drift_offset.x, -close_distance)
			_move_toward(target, surge_speed, delta)

		Action.CIRCLE_PLAYER:
			_circle_angle += delta * 1.2
			_target_pos    = player.global_position \
				+ Vector2(cos(_circle_angle), sin(_circle_angle)) * (close_distance * 1.4)
			_move_toward(_target_pos, base_speed * 1.3, delta)

func _move_toward(target: Vector2, speed: float, delta: float) -> void:
	var dir  := target - global_position
	var dist := dir.length()
	var desired := Vector2.ZERO
	if dist > 6.0:
		desired = dir.normalized() * min(dist * 4.0, speed)
	velocity = velocity.lerp(desired, acceleration * delta)

# ════════════════════════════════════════════════════════
#  DAMAGE, KNOCKBACK & DEATH
# ════════════════════════════════════════════════════════
func _on_weakpoint_damaged(amount: int, knockback: Vector2) -> void:
	if is_dead:
		return

	print("Boss hit for: ", amount, " | HP before: ", current_hp)  # debug — remove later
	current_hp = max(current_hp - amount, 0)
	# Clamp to 1 so HealthBar.gd never hits 0 and queue_free()s itself —
	# actual death + bar hiding is handled below in _die()
	health_bar.health = max(current_hp, 1)
	print("Boss HP after: ", current_hp)  # debug — remove later

	_flash_damage()
	_stagger()

	_action          = Action.FLY_UP
	_drift_offset    = Vector2(randf_range(-200.0, 200.0), 0.0)
	_action_timer    = 0.0
	_action_interval = randf_range(1.0, 1.8)

	if current_hp <= 0:
		_die()

func _stagger() -> void:
	_is_staggered = true
	velocity       = Vector2.ZERO
	await get_tree().create_timer(0.2).timeout
	_is_staggered  = false

func _flash_damage() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.5, 0.3, 0.3), 0.05)
	tween.tween_property(self, "modulate", Color.WHITE,           0.15)

func _die() -> void:
	is_dead = true
	weakpoint.set_deferred("monitoring",  false)
	weakpoint.set_deferred("monitorable", false)

	# Hide bar manually — stops HealthBar.gd from queue_free()ing itself at 0
	if is_instance_valid(health_bar):
		health_bar.visible = false

	for node in get_parent().get_children():
		if is_instance_valid(node) and node.has_meta("proj_active"):
			node.queue_free()

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
	await tween.finished
	queue_free()

# ════════════════════════════════════════════════════════
#  ATTACK TIMERS
# ════════════════════════════════════════════════════════
func _handle_attack_timers(delta: float) -> void:
	if player == null:
		return
	var rate := 0.6 if _main_phase == MainPhase.CLOSE else 1.0

	_attack1_timer -= delta
	if _attack1_timer <= 0.0:
		_attack1_timer = attack1_interval * rate
		_shoot_bullet(attack1_root.global_position)

	_attack2_timer -= delta
	if _attack2_timer <= 0.0:
		_attack2_timer = attack2_interval * rate
		_shoot_spread()

# ════════════════════════════════════════════════════════
#  PROJECTILE SPAWNING
# ════════════════════════════════════════════════════════
func _shoot_bullet(spawn_pos: Vector2) -> void:
	if _shooter1 == null:
		return
	_shooter1.shoot_at(spawn_pos, player.global_position)

func _shoot_spread() -> void:
	if _shooter2 == null:
		return
	var offsets : Array[Vector2] = [
		Vector2(-attack2_spread,       0.0),
		Vector2(-attack2_spread * 0.5, 0.0),
		Vector2( attack2_spread * 0.5, 0.0),
		Vector2( attack2_spread,       0.0),
	]
	var boss_pos   := attack2_root.global_position
	var player_pos := player.global_position
	for offset in offsets:
		_shooter2.shoot_at(boss_pos + offset, player_pos)
