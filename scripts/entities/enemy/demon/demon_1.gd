extends CharacterBody2D

@export var attack_range: float = 20.0
@export var move_speed: float = 90.0
@export var attack_cooldown: float = 2.0
@export var max_hp: int = 30                          # NEW
@onready var health_bar: ProgressBar = $HealthBar   # NEW
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox  
@export var knockback_friction: float = 800.0   # how fast knockback slows down
			 # NEW

var player: Node2D = null
var is_attacking: bool = false
var can_attack: bool = true
var current_hp: int                                   # NEW

var is_knocked_back: bool = false    # NEW
enum State { CHASE, ATTACK }
var state = State.CHASE

func _ready() -> void:
	current_hp = max_hp
	health_bar.max_value = max_hp                   # NEW
	health_bar.value = max_hp                                   # NEW
	hurtbox.damaged.connect(_on_damaged)              # NEW
	animated_sprite.animation_finished.connect(_on_attack_finished)
	print("hurtbox connected: ", hurtbox.damaged.is_connected(_on_damaged))

func _on_damaged(amount: int, knockback: Vector2) -> void:
	if current_hp <= 0:
		return
	current_hp -= amount
	health_bar.value = current_hp
	velocity = knockback
	is_knocked_back = true
	await get_tree().create_timer(0.25).timeout
	is_knocked_back = false
	if current_hp <= 0:
		_die()

func _die() -> void:                                  # NEW
	hurtbox.set_deferred("monitoring", false)
	#animated_sprite.play("death")
	#await animated_sprite.animation_finished
	queue_free()

func _physics_process(delta: float) -> void:
	if is_knocked_back:
		velocity = velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
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
	_handle_state()

func _update_state(distance: float) -> void:
	if is_attacking:
		return
	if distance <= attack_range and can_attack:
		state = State.ATTACK
	else:
		state = State.CHASE

func _handle_state() -> void:
	match state:
		State.CHASE:
			var direction := (player.global_position - global_position).normalized()
			if direction == Vector2.ZERO:
				direction = Vector2.RIGHT
			velocity = direction * move_speed
			animated_sprite.flip_h = player.global_position.x > global_position.x
			health_bar.scale.x = -1.0 if animated_sprite.flip_h else 1.0
			if animated_sprite.animation != "walk":
				animated_sprite.play("walk")
		State.ATTACK:
			velocity = Vector2.ZERO
			if not is_attacking:
				is_attacking = true
				can_attack = false
				animated_sprite.flip_h = player.global_position.x > global_position.x
				animated_sprite.play("attack")
	move_and_slide()

func _on_attack_finished() -> void:
	is_attacking = false
	state = State.CHASE
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true
