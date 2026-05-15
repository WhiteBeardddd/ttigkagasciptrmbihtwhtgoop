extends PlayerState

const DASH_DURATION := 0.18
var timer := 0.0
var dir   := 1.0

func enter(_prev: String, _data: Dictionary = {}) -> void:
	timer = DASH_DURATION
	dir   = -1.0 if player.anim.flip_h else 1.0
	player.dash_cooldown_timer = player.DASH_COOLDOWN
	player.play_anim("dash")

func physics_update(delta: float) -> void:
	timer -= delta

	if not player.is_on_floor():
		player.velocity.y += player.gravity * delta

	player.velocity.x = dir * player.dash_speed
	player.move_and_slide()

	if timer <= 0.0:
		finished.emit(IDLE if player.is_on_floor() else FALL)
