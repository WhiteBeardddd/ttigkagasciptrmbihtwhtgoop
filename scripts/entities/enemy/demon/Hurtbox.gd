# Hurtbox.gd
extends Area2D

signal damaged(amount: int, knockback: Vector2)

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	damaged.emit(amount, knockback)
