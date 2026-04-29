# CrouchAttack.gd
extends PlayerState
var _hitbox_spawned := false
func enter(_prev: String, _data: Dictionary = {}) -> void:
	_hitbox_spawned = false
	player.velocity.x = 0.0    # always stop, can't crouch in air
	player.attack_combo = 0
	player.play_anim("crouch_attack")
func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	if not _hitbox_spawned and player.anim.frame == 2:
		player.spawn_attack_hitbox("crouch_attack")
		_hitbox_spawned = true
	player.move_and_slide()
