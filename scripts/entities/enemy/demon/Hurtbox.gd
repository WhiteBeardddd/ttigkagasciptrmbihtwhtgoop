# Hurtbox.gd
extends Area2D

signal damaged(amount: int, knockback: Vector2)

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	# Check if the owner (knight) is invincible before emitting
	if get_parent().is_in_group("invincible"):
		return
	
	damaged.emit(amount, knockback)
