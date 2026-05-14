# Attack2.gd
extends PlayerState

var _hitbox_spawned := false

func enter(_prev: String, _data: Dictionary = {}) -> void:
	_hitbox_spawned = false
	if player.is_on_floor():
		player.velocity.x = 0.0
	player.play_anim("attack2")

func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	
	# Triggers on Frame 4
	if not _hitbox_spawned and player.anim.frame == 4:
		player.spawn_attack_hitbox("attack2")
		_hitbox_spawned = true
		
		var audio = player.get_node_or_null("AttackSound1")
		if audio:
			# Skip the first 0.15 seconds to bypass the empty silence
			audio.play(0.15)
			
	player.move_and_slide()

func exit() -> void:
	# Leave this empty so the sound finishes naturally without cutting off!
	pass
