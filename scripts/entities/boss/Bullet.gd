extends AnimatedSprite2D

@export var lifetime: float = 4.0

var bullet_damage:    int   = 0
var bullet_knockback: float = 0.0
var velocity:         Vector2 = Vector2.ZERO

var boss_hitbox_scene: PackedScene = preload("res://scenes/characters/boss_hitbox.tscn")

func _ready() -> void:
	var hitbox = boss_hitbox_scene.instantiate()
	hitbox.damage          = bullet_damage
	hitbox.knockback_force = bullet_knockback
	hitbox.source          = "enemy"
	add_child(hitbox)
	hitbox.area_entered.connect(_on_hit)

func _on_hit(other: Area2D) -> void:
	if other.is_in_group("enemy_hurtbox"):
		return
	queue_free()

func _process(delta: float) -> void:
	global_position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
