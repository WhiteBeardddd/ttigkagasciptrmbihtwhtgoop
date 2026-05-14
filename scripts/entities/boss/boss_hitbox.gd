extends Area2D

@export var damage:         int   = 20
@export var knockback_force: float = 350.0
@export var source:         String = "enemy"

var _hit_targets: Array = []

@onready var shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func set_shape_size(size: Vector2) -> void:
	if shape.shape is RectangleShape2D:
		shape.shape.size = size

func _on_area_entered(area: Area2D) -> void:
	if area in _hit_targets:
		return
	if area.is_in_group("enemy_hurtbox"):
		return
	if area.has_method("take_damage"):
		_hit_targets.append(area)
		var direction := (area.global_position - global_position).normalized()
		area.take_damage(damage, direction * knockback_force)
