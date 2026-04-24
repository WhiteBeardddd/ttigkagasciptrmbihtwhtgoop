extends CharacterBody2D

# ──────────────────────────────────────────────
#  MOON LORD AI — Flying / Erratic Movement
#  Attach to: MoonLordBoss (CharacterBody2D)
# ──────────────────────────────────────────────

# ── Player Reference ─────────────────────────
var player: Node2D = null

# ── Speed Settings ───────────────────────────
@export var base_speed:    float = 260.0
@export var surge_speed:   float = 480.0
@export var acceleration:  float = 5.0
@export var bob_amplitude: float = 8.0
@export var bob_speed:     float = 2.2

# ── Phase Durations ───────────────────────────
## How long the free-flying phase lasts
@export var fly_phase_duration:   float = 8.0
## How long the close/aggressive phase lasts
@export var close_phase_duration: float = 4.0

# ── Flying Phase Action Timing ────────────────
@export var fly_action_interval_min: float = 0.8
@export var fly_action_interval_max: float = 1.8

# ── Close Phase Action Timing ─────────────────
@export var close_action_interval_min: float = 0.5
@export var close_action_interval_max: float = 1.0

# ── Distances ────────────────────────────────
@export var hover_height:    float = 220.0
@export var close_distance:  float = 90.0
@export var fly_up_distance: float = 340.0
@export var side_dash_range: float = 300.0

# ── Phase Multipliers ─────────────────────────
@export var phase_speed_multipliers: Array[float] = [1.0, 1.45, 1.9]
var current_phase: int = 0

# ── Main Phase Enum ───────────────────────────
enum MainPhase { FLYING, CLOSE }

# ── Action Enum ───────────────────────────────
enum Action { HOVER, FLY_UP, SIDE_DASH, SURGE, SWOOP_CLOSE, CIRCLE_PLAYER }

# ── Internal State ───────────────────────────
var _main_phase       = MainPhase.FLYING
var _main_phase_timer: float   = 0.0
var _action           = Action.HOVER
var _action_timer:    float    = 0.0
var _action_interval: float    = 1.5
var _bob_timer:       float    = 0.0
var _target_pos:      Vector2  = Vector2.ZERO
var _drift_offset:    Vector2  = Vector2.ZERO
var _circle_angle:    float    = 0.0

# ── Shooter State ───────────────────────────

var projectile_shooter: MoonLordProjectileShooter

@onready var bullet_sprite: AnimatedSprite2D = $BulletSprite
@onready var main_weakpoint: CollisionShape2D = $MainWeakPoint
@onready var left_weakpoint: CollisionShape2D = $LeftSubWeakPoint
@onready var right_weakpoint: CollisionShape2D = $RightSubWeakPoint
@onready var main_fx: AnimatedSprite2D = $MainWeakPoint/HeadShootEffects
@onready var left_fx: AnimatedSprite2D = $LeftSubWeakPoint/Hand/LeftShootEffects
@onready var right_fx: AnimatedSprite2D = $RightSubWeakPoint/Hand/RightShootEffects
@onready var main_sfx: AudioStreamPlayer2D = $MainWeakPoint/HeadShootSFX
@onready var left_sfx: AudioStreamPlayer2D = $LeftSubWeakPoint/Hand/LeftShootSFX
@onready var right_sfx: AudioStreamPlayer2D = $RightSubWeakPoint/Hand/RightShootSFX

# ─────────────────────────────────────────────
func _ready() -> void:
	_find_player()
	_enter_flying_phase()
	projectile_shooter = MoonLordProjectileShooter.new()
	add_child(projectile_shooter)

	projectile_shooter.setup(
		player,
		bullet_sprite,
		[
			main_weakpoint,
			left_weakpoint,
			right_weakpoint
		],
		[
			main_fx,
			left_fx,
			right_fx
		],
		[
			main_sfx,
			left_sfx,
			right_sfx
		]
	)

func _physics_process(delta: float) -> void:
	if player == null:
		_find_player()
		return

	_bob_timer        += delta
	_action_timer     += delta
	_main_phase_timer += delta

	var phase_mult := _get_phase_speed_multiplier()
	projectile_shooter.update(delta)

	# ── Switch between FLYING and CLOSE phases ──
	match _main_phase:
		MainPhase.FLYING:
			if _main_phase_timer >= fly_phase_duration:
				print("FLying")
				_enter_close_phase()
		MainPhase.CLOSE:
			if _main_phase_timer >= close_phase_duration:
				print("Close")
				_enter_flying_phase()

	# ── Switch action when interval expires ──
	if _action_timer >= _action_interval:
		_action_timer = 0.0
		_pick_action()

	# ── Execute current action ────────────────
	match _action:

		Action.HOVER:
			var target := player.global_position \
				+ Vector2(_drift_offset.x, -hover_height + _drift_offset.y) \
				+ Vector2(0, sin(_bob_timer * bob_speed) * bob_amplitude)
			_move_toward(target, base_speed * phase_mult, delta)

		Action.FLY_UP:
			var target := player.global_position \
				+ Vector2(_drift_offset.x, -fly_up_distance)
			_move_toward(target, surge_speed * 0.85 * phase_mult, delta)

		Action.SIDE_DASH:
			var target := player.global_position + _drift_offset
			_move_toward(target, surge_speed * phase_mult, delta)

		Action.SURGE:
			_move_toward(_target_pos, surge_speed * 1.1 * phase_mult, delta)

		Action.SWOOP_CLOSE:
			var target := player.global_position \
				+ Vector2(_drift_offset.x, -close_distance)
			_move_toward(target, surge_speed * phase_mult, delta)

		Action.CIRCLE_PLAYER:
			# Slowly orbit the player during the close phase
			_circle_angle += delta * 1.2 * phase_mult
			var orbit_radius := close_distance * 1.4
			_target_pos = player.global_position \
				+ Vector2(cos(_circle_angle), sin(_circle_angle)) * orbit_radius
			_move_toward(_target_pos, base_speed * 1.3 * phase_mult, delta)


# ─────────────────────────────────────────────
#  Phase Transitions
# ─────────────────────────────────────────────

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


# ─────────────────────────────────────────────
#  Action Picker
# ─────────────────────────────────────────────

func _pick_action() -> void:
	match _main_phase:

		MainPhase.FLYING:
			_action_interval = randf_range(fly_action_interval_min, fly_action_interval_max)
			var roll := randf()

			if roll < 0.40:
				# Higher chance to fly upward
				_action = Action.FLY_UP
				_drift_offset = Vector2(randf_range(-250.0, 250.0), 0.0)

			elif roll < 0.75:
				# Side dash, but stay high above the player
				_action = Action.SIDE_DASH
				var side := 1.0 if randf() > 0.5 else -1.0
				_drift_offset = Vector2(
					side * randf_range(side_dash_range * 0.5, side_dash_range),
					-randf_range(220.0, 340.0)
				)

			elif roll < 0.95:
				# Surge around but mostly above the player
				_action = Action.SURGE
				_target_pos = player.global_position + Vector2(
					randf_range(-350.0, 350.0),
					-randf_range(200.0, 420.0)
				)

			else:
				# Hover high above
				_action = Action.HOVER
				_drift_offset = Vector2(
					randf_range(-180.0, 180.0),
					-randf_range(220.0, 320.0)
				)

		MainPhase.CLOSE:
			# Short intervals — aggressive, right on the player
			_action_interval = randf_range(close_action_interval_min, close_action_interval_max)
			var roll := randf()

			if roll < 0.45:
				# Swoop close — main threat
				_action = Action.SWOOP_CLOSE
				_drift_offset = Vector2(randf_range(-100.0, 100.0), 0.0)

			elif roll < 0.75:
				# Orbit / circle the player menacingly
				_action = Action.CIRCLE_PLAYER
				_circle_angle = randf_range(0.0, TAU)

			else:
				# Quick side swap while staying close
				_action = Action.SIDE_DASH
				var side := 1.0 if randf() > 0.5 else -1.0
				_drift_offset = Vector2(side * randf_range(60.0, 140.0), -close_distance)


# ─────────────────────────────────────────────
#  Movement
# ─────────────────────────────────────────────

func _move_toward(target: Vector2, speed: float, delta: float) -> void:
	var dir  := target - global_position
	var dist := dir.length()
	var desired_vel := Vector2.ZERO
	if dist > 6.0:
		desired_vel = dir.normalized() * min(dist * 4.0, speed)
	velocity = velocity.lerp(desired_vel, acceleration * delta)
	move_and_slide()


# ─────────────────────────────────────────────
#  Helpers
# ─────────────────────────────────────────────

func _get_phase_speed_multiplier() -> float:
	if current_phase < phase_speed_multipliers.size():
		return phase_speed_multipliers[current_phase]
	return phase_speed_multipliers[-1]


func _find_player() -> void:
	player = get_tree().current_scene.get_node("knight")
	if player == null:
		push_warning("MoonLordAI: No player found!")


# ─────────────────────────────────────────────
#  Public API
# ─────────────────────────────────────────────

func set_phase(phase_index: int) -> void:
	current_phase         = clamp(phase_index, 0, phase_speed_multipliers.size() - 1)
	# Later phases: shorter fly window, longer close window
	fly_phase_duration    = max(5.0, 8.0  - phase_index * 1.2)
	close_phase_duration  = min(6.0, 4.0  + phase_index * 0.8)
	close_action_interval_min = max(0.3, 0.5 - phase_index * 0.1)
	close_action_interval_max = max(0.5, 1.0 - phase_index * 0.2)
