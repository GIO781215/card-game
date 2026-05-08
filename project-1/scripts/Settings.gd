extends Control

const COLORS: Array = [
	Color(0.1, 0.1, 0.2, 1),   # 深藍（預設）
	Color(0.05, 0.2, 0.08, 1),  # 深綠
	Color(0.2, 0.05, 0.05, 1),  # 深紅
	Color(0.15, 0.05, 0.25, 1), # 深紫
	Color(0.05, 0.15, 0.25, 1), # 深青
]

const COLOR_NAMES: Array = ["深藍", "深綠", "深紅", "深紫", "深青"]

var _color_index: int = 0

func _ready() -> void:
	_find_current_color()
	$Background.color = GameState.background_color
	_update_button_label()

func _find_current_color() -> void:
	for i in COLORS.size():
		if COLORS[i].is_equal_approx(GameState.background_color):
			_color_index = i
			return

func _update_button_label() -> void:
	var next_index := (_color_index + 1) % COLORS.size()
	$CenterContainer/VBoxContainer/ChangeBgButton.text = "更改背景顏色 → " + COLOR_NAMES[next_index]

func _on_change_bg_pressed() -> void:
	_color_index = (_color_index + 1) % COLORS.size()
	GameState.background_color = COLORS[_color_index]
	$Background.color = GameState.background_color
	_update_button_label()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
