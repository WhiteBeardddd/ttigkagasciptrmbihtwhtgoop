# Fall.gd
extends PlayerState

func enter(_prev: String, _data: Dictionary = {}) -> void:
	player.play_anim("jump")

func physics_update(delta: float) -> void:
	player.tick_cooldowns(delta)
	player.apply_gravity(delta)
	player.apply_horizontal(Input.get_axis("move_left", "move_right"))
	player.move_and_slide()

	if player.is_on_wall():
		finished.emit(WALL_HANG)
	elif Input.is_action_just_pressed("dash") and player.dash_cooldown_timer <= 0.0:
		finished.emit(DASH)
	elif Input.is_action_just_pressed("roll") and player.roll_cooldown_timer <= 0.0:
		finished.emit(ROLL)
	elif player.is_on_floor():
		var dir := Input.get_axis("move_left", "move_right")
		finished.emit(RUN if dir != 0.0 else IDLE)
