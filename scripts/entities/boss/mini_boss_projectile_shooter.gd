extends Node
class_name MiniBossProjectileShooter

@export var bullet_speed         : float = 200.0
@export var rotate_to_direction  : bool  = false  # set true for Attack2 (ball faces player)

var player          : Node2D           = null
var bullet_template : AnimatedSprite2D = null  # set to AttackDesign node

# ─────────────────────────────────────────────
#  Fire a single bullet from spawn_pos → target_pos
# ─────────────────────────────────────────────
func shoot_at(spawn_pos: Vector2, target_pos: Vector2) -> void:
	if bullet_template == null:
		push_warning("MiniBossProjectileShooter: No bullet_template set!")
		return

	var direction := (target_pos - spawn_pos).normalized()

	var bullet := AnimatedSprite2D.new()
	bullet.set_script(preload("res://scripts/entities/boss/Bullet.gd"))

	# Copy visual properties from the AttackDesign template
	bullet.sprite_frames = bullet_template.sprite_frames
	bullet.animation     = bullet_template.animation
	bullet.scale         = bullet_template.scale
	bullet.modulate      = bullet_template.modulate
	bullet.flip_h        = bullet_template.flip_h
	bullet.flip_v        = bullet_template.flip_v

	bullet.global_position = spawn_pos

	# Attack1: no rotation (fires as-is)
	# Attack2: rotate so ball (top of sprite) faces travel direction
	if rotate_to_direction:
		bullet.rotation = direction.angle() + PI / 2.0
	else:
		bullet.rotation = 0.0

	bullet.play()
	bullet.velocity = direction * bullet_speed

	get_tree().current_scene.add_child(bullet)
