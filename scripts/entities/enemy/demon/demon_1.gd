extends CharacterBody2D

@export var attack_range: float = 20.0
@export var move_speed: float = 90.0
@export var attack_cooldown: float = 2.0
@export var max_hp: int = 30
@export var attack_damage: int = 10
@export var knockback_force: float = 200.0
@export var knockback_friction: float = 800.0

var hitbox_scene: PackedScene = preload("res://scenes/characters/Hitbox.tscn")

@onready var health_bar = $HealthBar
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var aggro_zone: Area2D = $AggroZone
@onready var collision_1 = $CollisionShape2D
@onready var collision_2 = $Hurtbox/CollisionShape2D

var player: Node2D = null
var is_attacking: bool = false
var can_attack: bool = true
var current_hp: int
var is_knocked_back: bool = false
var is_dead: bool = false
var is_aggro: bool = false
var _hitbox_spawned: bool = false

const ATTACK_DATA = [1, 32, 17, 50, 40, 0.12, 250.0]

enum State { IDLE, CHASE, ATTACK }
var state = State.IDLE

func _ready() -> void:
	current_hp = max_hp
	health_bar.init_health(max_hp)
	hurtbox.damaged.connect(_on_damaged)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.frame_changed.connect(_on_frame_changed)
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
	collision_1.queue_free()
	collision_2.queue_free()
	is_dead = true
	if animated_sprite.animation_finished.is_connected(_on_animation_finished):
		animated_sprite.animation_finished.disconnect(_on_animation_finished)
	if animated_sprite.frame_changed.is_connected(_on_frame_changed):
		animated_sprite.frame_changed.disconnect(_on_frame_changed)
	if is_instance_valid(hurtbox):
		hurtbox.set_deferred("monitoring", false)
	velocity = Vector2.ZERO
	animated_sprite.play("death")
	animated_sprite.animation_finished.connect(_on_death_animation_finished, CONNECT_ONE_SHOT)

func _on_death_animation_finished() -> void:
	queue_free()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if is_knocked_back:
		velocity = velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
		move_and_slide()
		return

	if not is_aggro:
		velocity = Vector2.ZERO
		if not is_attacking:
			if animated_sprite.animation != "idle" or not animated_sprite.is_playing():
				animated_sprite.play("idle")
		move_and_slide()
		return

	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		if not is_attacking:
			animated_sprite.play("idle")
		move_and_slide()
		return

	var distance := global_position.distance_to(player.global_position)
	_update_state(distance)
	_handle_state(delta)

func _update_state(distance: float) -> void:
	if is_attacking:
		return
	if distance <= attack_range and can_attack:
		state = State.ATTACK
	else:
		state = State.CHASE

func _handle_state(_delta: float) -> void:
	match state:
		State.CHASE:
			var direction := (player.global_position - global_position).normalized()
			var distance: float = global_position.distance_to(player.global_position)
			if distance <= attack_range and not can_attack:
				velocity = Vector2.ZERO
				if animated_sprite.animation != "idle" or not animated_sprite.is_playing():
					animated_sprite.play("idle")
			else:
				velocity = direction * move_speed
				animated_sprite.flip_h = player.global_position.x > global_position.x
				if animated_sprite.animation != "walk" or not animated_sprite.is_playing():
					animated_sprite.play("walk")
			health_bar.scale.x = 1.0

		State.ATTACK:
			velocity = Vector2.ZERO
			if not is_attacking:
				is_attacking = true
				can_attack = false
				_hitbox_spawned = false
				animated_sprite.flip_h = player.global_position.x > global_position.x
				health_bar.scale.x = 1.0
				animated_sprite.play("attack")
	move_and_slide()

func _on_frame_changed() -> void:
	if is_dead:
		return
	if animated_sprite.animation == "attack":
		if animated_sprite.frame == 3 and not _hitbox_spawned:
			_spawn_attack_hitbox()
			_hitbox_spawned = true

func _spawn_attack_hitbox() -> void:
	if hitbox_scene == null:
		return
	var hitbox = hitbox_scene.instantiate()
	hitbox.source = "enemy"
	hitbox.damage = ATTACK_DATA[0]
	hitbox.lifetime = ATTACK_DATA[5]
	hitbox.knockback_force = ATTACK_DATA[6]
	var sign_x = 1.0 if animated_sprite.flip_h else -1.0
	hitbox.global_position = global_position + Vector2(ATTACK_DATA[1] * sign_x, ATTACK_DATA[2])
	hitbox.scale.x = sign_x
	get_tree().current_scene.add_child(hitbox)
	hitbox.set_shape_size(Vector2(ATTACK_DATA[3], ATTACK_DATA[4]))

func _on_animation_finished() -> void:
	if is_dead:
		return
	match animated_sprite.animation:
		"attack":
			is_attacking = false
			state = State.CHASE
			await get_tree().create_timer(attack_cooldown).timeout
			if is_dead:
				return
			can_attack = true

func _flash_damage() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.5, 0.3, 0.3), 0.05)
	tween.tween_property(self, "modulate", Color.WHITE,           0.15)
