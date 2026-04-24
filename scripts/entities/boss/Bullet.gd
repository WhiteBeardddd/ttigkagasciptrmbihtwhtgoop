extends AnimatedSprite2D
@export var lifetime: float = 4.0

#@onready var particles: GPUParticles2D = $BulletSprite/GPUParticles2D

var velocity: Vector2 = Vector2.ZERO

#func _ready():
	#particles.emitting = true

func _process(delta: float) -> void:
	global_position += velocity * delta

	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
