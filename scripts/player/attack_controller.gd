# AttackController.gd
extends Node2D

@export var hitbox_scene: PackedScene

var facing_right := true

const ATTACK_DATA := { # [dmg, x, y, width, height, timeframe, knockback]
	"attack1":       [12, 32,  17,  50, 40, 0.12, 250.0],
	"attack2":       [18, 32,  17,  50, 40, 0.14, 350.0],
	"attack3":       [25, 32,  17,  50, 40, 0.16, 500.0],
	"crouch_attack": [10, 32,  17,  50, 40, 0.10, 100.0],
}

func spawn_hitbox(attack_name: String) -> void:
	if not ATTACK_DATA.has(attack_name):
		return
	var cfg    = ATTACK_DATA[attack_name]
	var hitbox = hitbox_scene.instantiate()
	hitbox.damage   = cfg[0]
	hitbox.lifetime = cfg[5]
	hitbox.knockback_force = cfg[6]
	var sign_x = 1.0 if facing_right else -1.0
	var knight = get_tree().get_first_node_in_group("player")
	var origin = knight.global_position
	hitbox.global_position = origin + Vector2(cfg[1] * sign_x, cfg[2])
	hitbox.scale.x = sign_x
	get_tree().current_scene.add_child(hitbox)
	hitbox.set_shape_size(Vector2(cfg[3], cfg[4]))
