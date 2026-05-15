# Run.gd
extends PlayerState

func enter(_prev: String, _data: Dictionary = {}) -> void:
	player.play_anim("run")

func physics_update(delta: float) -> void:
	player.tick_cooldowns(delta)
	player.apply_gravity(delta)
	var dir := Input.get_axis("move_left", "move_right")
	player.apply_horizontal(dir)
	player.move_and_slide()

	if Input.is_action_just_pressed("attack1"):
		player.attack_combo = 1
		player.combo_timer = player.COMBO_WINDOW
		finished.emit(ATTACK1)
		return
	elif Input.is_action_just_pressed("attack2"):
		finished.emit(ATTACK2)
		return
	elif Input.is_action_just_pressed("attack3"):
		finished.emit(ATTACK3)
		return

	if not player.is_on_floor():
		finished.emit(FALL)
	elif Input.is_action_just_pressed("jump"):
		finished.emit(JUMP)
	elif Input.is_action_just_pressed("dash") and player.dash_cooldown_timer <= 0.0:
		finished.emit(DASH)
	elif Input.is_action_just_pressed("roll") and player.roll_cooldown_timer <= 0.0:
		finished.emit(ROLL)
	elif Input.is_action_pressed("crouch"):
		finished.emit(CROUCH_WALK)
	elif dir == 0.0:
		finished.emit(IDLE)
