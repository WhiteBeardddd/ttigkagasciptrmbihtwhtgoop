extends Node
class_name MoonLordProjectileShooter

@export var bullet_speed: float = 1000.0
@export var shoot_interval: float = 2.2
@export var delay_between_shots: float = 0.1   # delay per weakpoint

var player: Node2D
var bullet_template: AnimatedSprite2D

var weakpoints: Array[CollisionShape2D] = []
var shoot_effects: Array[AnimatedSprite2D] = []
var shoot_sounds: Array[AudioStreamPlayer2D] = []

var _timer: float = 0.0


func setup(
	p_player: Node2D,
	p_bullet_template: AnimatedSprite2D,
	p_weakpoints: Array[CollisionShape2D],
	p_effects: Array[AnimatedSprite2D],
	p_sounds: Array[AudioStreamPlayer2D]
) -> void:
	player = p_player
	bullet_template = p_bullet_template
	weakpoints = p_weakpoints
	shoot_effects = p_effects
	shoot_sounds = p_sounds


func update(delta: float) -> void:
	if player == null or bullet_template == null:
		return

	_timer += delta

	if _timer >= shoot_interval:
		_timer = 0.0
		_shoot_sequence()


# SHOOT ONE BY ONE WITH DELAY
func _shoot_sequence() -> void:
	for i in range(weakpoints.size()):
		await get_tree().create_timer(i * delay_between_shots).timeout

		var wp = weakpoints[i]
		var fx = shoot_effects[i]
		var sfx = shoot_sounds[i]

		if wp != null:
			_play_effect(fx)
			_play_sound(sfx)
			_shoot_from(wp)


func _play_effect(effect: AnimatedSprite2D) -> void:
	if effect == null:
		return

	effect.stop()
	effect.frame = 0
	effect.play()

func _play_sound(sfx: AudioStreamPlayer2D) -> void:
	if sfx == null:
		return
	
	# Restart sound cleanly
	sfx.stop()
	sfx.play()

func _shoot_from(point: CollisionShape2D) -> void:
	var spawn_position := point.global_position
	var direction := (player.global_position - spawn_position).normalized()

	var bullet := AnimatedSprite2D.new()
	bullet.set_script(preload("res://scripts/entities/boss/Bullet.gd"))

	bullet.sprite_frames = bullet_template.sprite_frames
	bullet.animation = bullet_template.animation
	bullet.scale = bullet_template.scale
	bullet.modulate = bullet_template.modulate

	bullet.global_position = spawn_position
	bullet.rotation = direction.angle() - PI / 2

	bullet.play()
	bullet.velocity = direction * bullet_speed

	get_tree().current_scene.add_child(bullet)
