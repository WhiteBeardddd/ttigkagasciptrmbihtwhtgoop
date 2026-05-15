extends Area2D

@onready var mini_boss_scene = preload("res://scenes/boss/mini-boss.tscn")
@onready var portal_area:   Area2D = $"../../PortalArea"
@onready var monster_wrath: Area2D = $"../../Monsterwrath"

var is_spawned: bool = false

signal boss_defeated

func _ready() -> void:
	# Hide both until boss is defeated
	if portal_area:   portal_area.visible   = false
	if monster_wrath: monster_wrath.visible = false

func _on_body_entered(body: Node) -> void:
	if body.name == "knight" and not is_spawned:
		is_spawned = true
		print("Knight entered — spawning MiniBoss!")
		var boss = mini_boss_scene.instantiate()
		get_parent().add_child(boss)
		boss.global_position = global_position + Vector2(0, -150)
		boss.tree_exiting.connect(_on_boss_defeated)

func _on_boss_defeated() -> void:
	print("MiniBoss defeated!")
	boss_defeated.emit()
	if portal_area:   portal_area.visible   = true
	if monster_wrath: monster_wrath.visible = true
