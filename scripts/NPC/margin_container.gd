extends MarginContainer

signal finished_displaying

const MAX_WIDTH: int = 256

@export var letter_time: float = 0.03
@export var space_time: float = 0.06
@export var punctuation_time: float = 0.2

@onready var label: Label = $MarginContainer/VBoxContainer/Label
@onready var name_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/Label
@onready var timer: Timer = $LetterDisplayTimer

var _full_text: String = ""
var _letter_index: int = 0

func display_text(text_to_display: String, speaker_name: String = "") -> void:
	print("speaker_name received: '", speaker_name, "'")
	print("name_label node: ", name_label)
	
	if speaker_name == "":
		name_label.hide()
	else:
		name_label.text = speaker_name
		name_label.show()
		print("name set to: ", name_label.text, " visible: ", name_label.visible)

	_full_text = text_to_display
	label.text = text_to_display
	
	await resized
	custom_minimum_size.x = min(size.x, MAX_WIDTH)
	
	if size.x > MAX_WIDTH:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
		await resized
		await get_tree().process_frame
		custom_minimum_size.y = size.y
		
	global_position.x -= size.x / 2.0
	global_position.y -= size.y + 24.0
	
	label.text = ""
	_letter_index = 0
	_display_letter()
	
func _display_letter() -> void:
	label.text += _full_text[_letter_index]
	_letter_index += 1
	
	if _letter_index >= _full_text.length():
		timer.stop()
		finished_displaying.emit()
		return
	
	match _full_text[_letter_index]:
		"!", ".", ",", "?":
			timer.start(punctuation_time)
		" ":
			timer.start(space_time)
		_:
			timer.start(letter_time)

func _on_letter_display_timer_timeout() -> void:
	_display_letter()
