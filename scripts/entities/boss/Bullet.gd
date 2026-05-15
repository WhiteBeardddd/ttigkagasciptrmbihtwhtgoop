extends AnimatedSprite2D

@export var lifetime      : float   = 4.0
var bullet_damage         : int     = 0
var bullet_knockback      : float   = 0.0
var hitbox_delay          : float   = 0.15
var velocity              : Vector2 = Vector2.ZERO
var boss_hitbox_scene     : PackedScene = preload("res://scenes/characters/boss_hitbox.tscn")

var _hitbox : Node = null
var _hit    : bool = false

func _ready() -> void:
	var hitbox = boss_hitbox_scene.instantiate()
	hitbox.damage          = bullet_damage
	hitbox.knockback_force = bullet_knockback
	hitbox.source          = "enemy"

	hitbox.monitoring  = false
	hitbox.monitorable = false

	hitbox.collision_layer = 0
	hitbox.collision_mask  = 0b0100  # Layer 3 only (knight hurtbox)

	add_child(hitbox)
	_hitbox = hitbox
	hitbox.area_entered.connect(_on_hit)

	await get_tree().create_timer(hitbox_delay).timeout
	if is_instance_valid(_hitbox):
		_hitbox.monitoring  = true
		_hitbox.monitorable = true

func _on_hit(other: Area2D) -> void:
	print("Bullet hit: ", other.name, " | parent: ", other.get_parent().name, " | groups: ", other.get_groups())
	if _hit:
		return
	if other.is_in_group("enemy_hurtbox"):
		return
	_hit = true
	velocity = Vector2.ZERO

	if is_instance_valid(_hitbox):
		_hitbox.monitoring  = false
		_hitbox.monitorable = false

	if sprite_frames and sprite_frames.has_animation("explode") and animation != "explode":
		play("explode")
		await animation_finished

	queue_free()

func _process(delta: float) -> void:
	global_position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
