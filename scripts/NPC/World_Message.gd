extends Area2D

@export var lines: Array[String] = []
@export var npc_name: String = ""

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var prompt_label: Label = $Label

func _ready() -> void:
	prompt_label.hide()
	print("NPC name is: '", npc_name, "'")

func _on_body_entered(body: Node2D) -> void:
	if body.name == "knight":
		if not DialogManager.is_dialog_active:
			sprite.flip_h = body.global_position.x < global_position.x
			var spawn_position = global_position + Vector2(0, -50)
			DialogManager.start_dialog(spawn_position, lines, npc_name)

func _on_body_exited(body: Node2D) -> void:
	if body.name == "knight":
		prompt_label.hide()
