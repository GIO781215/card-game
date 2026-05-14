extends Control

func _ready() -> void:
	$Background.color = GameState.background_color
	%Card.visible = false
	_apply_card_style()

func _apply_card_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.set_corner_radius_all(12)
	style.set_border_width_all(3)
	style.border_color = Color(0.4, 0.4, 0.45)
	%Card.add_theme_stylebox_override("panel", style)

func _on_toggle_card_pressed() -> void:
	%Card.visible = !%Card.visible
	%ToggleCardButton.text = "隱藏卡牌" if %Card.visible else "顯示卡牌"

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
