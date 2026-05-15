# Idle.gd
extends PlayerState

func enter(_prev: String, _data: Dictionary = {}) -> void:
	player.play_anim("idle")
	player.velocity.x = 0.0

func physics_update(delta: float) -> void:
	player.tick_cooldowns(delta)
	player.apply_gravity(delta)
	player.move_and_slide()
	var dir := Input.get_axis("move_left", "move_right")

	if not player.is_on_floor():
		finished.emit(FALL)
	elif Input.is_action_just_pressed("jump"):
		finished.emit(JUMP)
	elif Input.is_action_just_pressed("dash") and player.dash_cooldown_timer <= 0.0:
		finished.emit(DASH)
	elif Input.is_action_just_pressed("roll") and player.roll_cooldown_timer <= 0.0:
		finished.emit(ROLL)
	elif Input.is_action_pressed("crouch"):
		finished.emit(CROUCH)
	elif Input.is_action_just_pressed("attack1"):
		player.attack_combo = 1
		player.combo_timer = player.COMBO_WINDOW
		finished.emit(ATTACK1)
	elif Input.is_action_just_pressed("attack2"):
		finished.emit(ATTACK2)
	elif Input.is_action_just_pressed("attack3"):
		finished.emit(ATTACK3)
	elif dir != 0.0:
		finished.emit(RUN)
