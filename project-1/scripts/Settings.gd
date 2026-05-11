extends Control

func _ready() -> void:
	GameState.apply_background($BgImage)
	_update_bg_button()
	_update_scale_buttons()
	_update_label_colors()

func _update_bg_button() -> void:
	%BgToggle.text = "關閉背景" if GameState.background_enabled else "開啟背景"

func _update_label_colors() -> void:
	GameState.apply_label_color($CenterContainer/VBoxContainer/Title)
	GameState.apply_label_color($CenterContainer/VBoxContainer/ScaleLabel)
	GameState.apply_label_color($CenterContainer/VBoxContainer/BgLabel)

func _update_scale_buttons() -> void:
	%SmallButton.modulate  = Color(1, 1, 0) if GameState.ui_scale_level == 0 else Color.WHITE
	%MediumButton.modulate = Color(1, 1, 0) if GameState.ui_scale_level == 1 else Color.WHITE
	%LargeButton.modulate  = Color(1, 1, 0) if GameState.ui_scale_level == 2 else Color.WHITE
	%XLargeButton.modulate = Color(1, 1, 0) if GameState.ui_scale_level == 3 else Color.WHITE

func _on_scale_small_pressed() -> void:
	GameState.ui_scale_level = 0
	GameState.apply_ui_scale()
	_update_scale_buttons()

func _on_scale_medium_pressed() -> void:
	GameState.ui_scale_level = 1
	GameState.apply_ui_scale()
	_update_scale_buttons()

func _on_scale_large_pressed() -> void:
	GameState.ui_scale_level = 2
	GameState.apply_ui_scale()
	_update_scale_buttons()

func _on_scale_xlarge_pressed() -> void:
	GameState.ui_scale_level = 3
	GameState.apply_ui_scale()
	_update_scale_buttons()

func _on_bg_toggle_pressed() -> void:
	GameState.background_enabled = !GameState.background_enabled
	$BgImage.visible = GameState.background_enabled
	_update_bg_button()
	_update_label_colors()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
