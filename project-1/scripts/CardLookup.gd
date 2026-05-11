extends Control

func _ready() -> void:
	GameState.apply_background($BgImage)
	GameState.apply_label_color($MarginContainer/VBoxContainer/Title)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
