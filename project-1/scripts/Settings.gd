extends Control

func _ready() -> void:
	GameState.apply_background($BgImage)
	_update_bg_button()
	_update_scale_buttons()
	_update_label_colors()

func _update_bg_button() -> void:
	%BgToggle.text = "關閉背景" if GameState.background_enabled else "開啟背景"

func _update_label_colors() -> void:
	GameState.apply_label_color($MarginContainer/VBoxContainer/Title)
	GameState.apply_label_color($MarginContainer/VBoxContainer/ScaleLabel)
	GameState.apply_label_color($MarginContainer/VBoxContainer/BgLabel)

func _update_scale_buttons() -> void:
	var base := %SmallButton.get_theme_stylebox("normal") as StyleBoxFlat
	var base_alpha := base.bg_color.a if base else 0.5

	var selected_style := StyleBoxFlat.new()
	selected_style.bg_color = Color(0.45, 0.75, 1.0, base_alpha)
	selected_style.set_corner_radius_all(6)
	selected_style.set_content_margin_all(8)

	var buttons := [%SmallButton, %MediumButton, %LargeButton]
	for i in range(buttons.size()):
		var btn: Button = buttons[i]
		if i == GameState.ui_scale_level:
			btn.add_theme_stylebox_override("normal", selected_style)
			btn.add_theme_stylebox_override("hover",   selected_style)
			btn.add_theme_stylebox_override("pressed", selected_style)
			btn.add_theme_color_override("font_color", Color.WHITE)
		else:
			btn.remove_theme_stylebox_override("normal")
			btn.remove_theme_stylebox_override("hover")
			btn.remove_theme_stylebox_override("pressed")
			btn.remove_theme_color_override("font_color")

func _on_scale_small_pressed() -> void:
	GameState.ui_scale_level = 0
	GameState.apply_ui_scale()
	GameState.save_data()
	_update_scale_buttons()

func _on_scale_medium_pressed() -> void:
	GameState.ui_scale_level = 1
	GameState.apply_ui_scale()
	GameState.save_data()
	_update_scale_buttons()

func _on_scale_large_pressed() -> void:
	GameState.ui_scale_level = 2
	GameState.apply_ui_scale()
	GameState.save_data()
	_update_scale_buttons()


func _on_bg_toggle_pressed() -> void:
	GameState.background_enabled = !GameState.background_enabled
	$BgImage.visible = GameState.background_enabled
	GameState.save_data()
	_update_bg_button()
	_update_label_colors()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
