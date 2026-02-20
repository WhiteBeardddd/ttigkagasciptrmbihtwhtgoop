extends Control

@onready var base = $Base
@onready var choose_mode = $ChooseAMode
@onready var lobbies = $Lobbies

func _ready():
	base.visible = true
	choose_mode.visible = false
	lobbies.visible = false

func _on_start_game_button_pressed() -> void:
	base.visible = false
	choose_mode.visible = true

func _on_free_for_all_button_pressed() -> void:
	choose_mode.visible = false
	lobbies.visible = true
