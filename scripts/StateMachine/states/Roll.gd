extends PlayerState

const ROLL_DURATION := 0.4
var timer := 0.0
var dir   := 1.0

func enter(_prev: String, _data: Dictionary = {}) -> void:
	timer = ROLL_DURATION
	dir   = -1.0 if player.anim.flip_h else 1.0
	player.roll_cooldown_timer = player.ROLL_COOLDOWN
	player.play_anim("roll")
	player.add_to_group("invincible")

func physics_update(delta: float) -> void:
	player.tick_cooldowns(delta)
	timer -= delta

	if not player.is_on_floor():
		player.velocity.y += player.gravity * delta

	player.velocity.x = dir * player.roll_speed
	player.move_and_slide()

	if timer <= 0.0:
		finished.emit(IDLE if player.is_on_floor() else FALL)

func exit() -> void:
	player.remove_from_group("invincible")
