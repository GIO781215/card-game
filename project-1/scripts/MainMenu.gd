extends Control

func _ready() -> void:
	$Background.color = GameState.background_color

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
