extends AnimatedSprite2D

var velocity: Vector2 = Vector2.ZERO
@export var lifetime: float = 4.0

func _process(delta: float) -> void:
	global_position += velocity * delta

	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
