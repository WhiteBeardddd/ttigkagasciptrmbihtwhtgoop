# Attack3.gd
extends PlayerState
var _hitbox_spawned := false
func enter(_prev: String, _data: Dictionary = {}) -> void:
	_hitbox_spawned = false
	if player.is_on_floor():
		player.velocity.x = 0.0
	player.attack_combo = 0
	player.play_anim("attack3")
func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	if not _hitbox_spawned and player.anim.frame == 5:
		player.spawn_attack_hitbox("attack3")
		_hitbox_spawned = true
	player.move_and_slide()
