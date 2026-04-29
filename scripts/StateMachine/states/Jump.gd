extends PlayerState

func enter(_prev: String, _data: Dictionary = {}) -> void:
	player.velocity.y = player.jump_velocity
	player.play_anim("jump")

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack1"):
		finished.emit("Attack1")
	if event.is_action_pressed("attack2"):
		finished.emit("Attack2")
	if event.is_action_pressed("attack3"):
		finished.emit("Attack3")

func physics_update(delta: float) -> void:
	player.apply_gravity(delta)
	player.apply_horizontal(Input.get_axis("move_left", "move_right"))
	player.move_and_slide()
	if player.is_on_wall():
		finished.emit(WALL_HANG)
	elif player.velocity.y >= 0.0:
		finished.emit(FALL)
