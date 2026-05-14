extends ProgressBar

@onready var timer = $Timer
@onready var damage_bar = $DamageBar

var health = 0 : set = _set_health
var drain_active := false

func init_health(_health):
	health = _health
	max_value = health
	value = health
	damage_bar.max_value = health
	damage_bar.value = health

func _set_health(new_health):
	var prev_health = health
	health = min(max_value, new_health)
	value = health
	if health <= 0:
		queue_free()
	if health < prev_health:
		timer.start()
		drain_active = false   # pause draining while waiting
	else:
		damage_bar.value = health

func _process(delta: float) -> void:
	if drain_active and damage_bar.value > value:
		damage_bar.value = move_toward(damage_bar.value, value, max_value * 0.3 * delta)

func _on_timer_timeout() -> void:
	drain_active = true
