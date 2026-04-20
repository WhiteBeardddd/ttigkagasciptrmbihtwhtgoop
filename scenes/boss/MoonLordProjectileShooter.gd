extends Node
class_name MoonLordProjectileShooter

@export var bullet_speed: float = 700.0
@export var shoot_interval: float = 1.2

var player: Node2D
var bullet_template: AnimatedSprite2D
var weakpoints: Array[CollisionShape2D] = []

var _timer: float = 0.0


func setup(
	p_player: Node2D,
	p_bullet_template: AnimatedSprite2D,
	p_weakpoints: Array[CollisionShape2D]
) -> void:
	player = p_player
	bullet_template = p_bullet_template
	weakpoints = p_weakpoints


func update(delta: float) -> void:
	if player == null or bullet_template == null:
		return

	_timer += delta

	if _timer >= shoot_interval:
		_timer = 0.0

		for weakpoint in weakpoints:
			if weakpoint != null:
				_shoot_from(weakpoint)


func _shoot_from(point: CollisionShape2D) -> void:
	var spawn_position := point.global_position
	var direction := (player.global_position - spawn_position).normalized()

	var bullet := AnimatedSprite2D.new()
	bullet.set_script(preload("res://scenes/boss/Bullet.gd"))

	bullet.sprite_frames = bullet_template.sprite_frames
	bullet.animation = bullet_template.animation
	bullet.scale = bullet_template.scale
	bullet.modulate = bullet_template.modulate

	bullet.global_position = spawn_position
	bullet.rotation = direction.angle()

	bullet.play()

	bullet.velocity = direction * bullet_speed

	get_tree().current_scene.add_child(bullet)
