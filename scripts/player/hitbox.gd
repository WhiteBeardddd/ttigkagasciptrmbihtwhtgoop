# Hitbox.gd  — scene: Area2D → CollisionShape2D (RectangleShape2D)
extends Area2D

@export var damage  : int   = 10
@export var lifetime: float = 0.15
@export var knockback_force: float = 300.0

@onready var shape: CollisionShape2D = $CollisionShape2D

# Tracks which enemies were already hit this swing (prevents double-damage)
var _hit_targets: Array = []

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func set_shape_size(size: Vector2) -> void:
	(shape.shape as RectangleShape2D).size = size  # remove the print lines

func _on_area_entered(area: Area2D) -> void:
	if area in _hit_targets:
		return
	if area.has_method("take_damage"):
		_hit_targets.append(area)
		var direction = Vector2(sign(scale.x), -0.3).normalized()
		area.take_damage(damage, direction * knockback_force)
