# Attack1.gd
extends PlayerState
var _hitbox_spawned := false
func enter(_prev: String, _data: Dictionary = {}) -> void:
	_hitbox_spawned = false
	if player.is_on_floor():
		player.velocity.x = 0.0
	player.play_anim("attack1")
func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack1") and player.combo_timer > 0.0:
		player.attack_combo = 2
func physics_update(delta: float) -> void:
	player.combo_timer = maxf(player.combo_timer - delta, 0.0)
	player.apply_gravity(delta)
	if not _hitbox_spawned and player.anim.frame == 3:
		player.spawn_attack_hitbox("attack1")
		_hitbox_spawned = true
	player.move_and_slide()
