extends CharacterBody2D

@export var attack_range: float = 35.0
@export var move_speed: float = 60.0
@export var attack_cooldown: float = 2.0
@export var max_hp: int = 50
@export var knockback_force: float = 200.0
@export var knockback_friction: float = 800.0

# --- Summoning ---
@export var summon_interval: float = 2.5
@export var max_minions: int = 6
@export var summons_per_interval: int = 4
var minion_scene: PackedScene = preload("res://scenes/enemy/GoatEnemy.tscn")
var active_minions: Array = []
var summon_timer: float = 0.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity") as float

@onready var health_bar = $HealthBar
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var aggro_zone: Area2D = $AggroZone
@onready var collision_1 = $CollisionShape2D
@onready var collision_2 = $Hurtbox/CollisionShape2D

var player: Node2D = null
var current_hp: int
var is_knocked_back: bool = false
var is_dead: bool = false
var is_aggro: bool = false
var is_summoning: bool = false

enum State { IDLE, CHASE }
var state = State.IDLE

func _ready() -> void:
	current_hp = max_hp
	health_bar.init_health(max_hp)
	hurtbox.damaged.connect(_on_damaged)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	aggro_zone.body_entered.connect(_on_aggro_zone_body_entered)
	aggro_zone.body_exited.connect(_on_aggro_zone_body_exited)

func _on_aggro_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		is_aggro = true

func _on_aggro_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_aggro = false

func _on_damaged(amount: int, knockback: Vector2) -> void:
	if is_dead:
		return
	is_aggro = true
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	current_hp -= amount
	if is_instance_valid(health_bar):
		health_bar.health = current_hp
	velocity = knockback
	is_knocked_back = true
	_flash_damage()
	await get_tree().create_timer(0.25).timeout
	if is_dead:
		return
	is_knocked_back = false
	if current_hp <= 0:
		_die()

func _die() -> void:
	if is_dead:
		return
	is_dead = true

	# Shut down incoming damage FIRST before freeing anything
	if is_instance_valid(hurtbox):
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)

	if hurtbox.damaged.is_connected(_on_damaged):
		hurtbox.damaged.disconnect(_on_damaged)

	collision_1.queue_free()
	collision_2.queue_free()

	for minion in active_minions:
		if is_instance_valid(minion):
			minion.queue_free()
	active_minions.clear()

	if animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.disconnect(_on_animation_finished)

	velocity = Vector2.ZERO
	animated_sprite.play("death")
	animated_sprite.animation_finished.connect(_on_death_animation_finished, CONNECT_ONE_SHOT)

func _on_death_animation_finished() -> void:
	queue_free()

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += gravity * delta

	if is_knocked_back:
		velocity.x = move_toward(velocity.x, 0, knockback_friction * delta)
		move_and_slide()
		return

	if is_summoning:
		velocity.x = 0.0
		move_and_slide()
		return

	if not is_aggro:
		velocity.x = 0.0
		if animated_sprite.animation != "idle" or not animated_sprite.is_playing():
			animated_sprite.play("idle")
		move_and_slide()
		return

	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		velocity.x = 0.0
		animated_sprite.play("idle")
		move_and_slide()
		return

	active_minions = active_minions.filter(func(m): return is_instance_valid(m))

	if active_minions.size() < max_minions:
		summon_timer += delta
		if summon_timer >= summon_interval:
			summon_timer = 0.0
			_start_summon()
			return

	var distance := global_position.distance_to(player.global_position)
	_update_state(distance)
	_handle_state()

func _update_state(distance: float) -> void:
	if distance < attack_range:
		state = State.CHASE
	else:
		state = State.IDLE

func _handle_state() -> void:
	match state:
		State.IDLE:
			velocity.x = 0.0
			if animated_sprite.animation != "idle" or not animated_sprite.is_playing():
				animated_sprite.play("idle")

		State.CHASE:
			var direction_x: float = signf(global_position.x - player.global_position.x)
			velocity.x = direction_x * move_speed
			animated_sprite.flip_h = player.global_position.x > global_position.x
			if animated_sprite.animation != "float move" or not animated_sprite.is_playing():
				animated_sprite.play("float move")

	move_and_slide()

func _start_summon() -> void:
	is_summoning = true
	velocity.x = 0.0
	animated_sprite.play("summon")

func _on_animation_finished() -> void:
	if is_dead:
		return
	match animated_sprite.animation:
		"summon":
			_spawn_minions()
			is_summoning = false

func _spawn_minions() -> void:
	var spots_left: int = max_minions - active_minions.size()
	var to_spawn: int = mini(summons_per_interval, spots_left)
	var facing: float = 1.0 if animated_sprite.flip_h else -1.0
	for i in to_spawn:
		var minion = minion_scene.instantiate()
		var offset := Vector2(facing * randf_range(30.0, 80.0), 0.0)
		minion.global_position = global_position + offset
		get_tree().current_scene.add_child(minion)
		minion.player = player
		minion.is_aggro = true
		active_minions.append(minion)

func _flash_damage() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.5, 0.3, 0.3), 0.05)
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)
