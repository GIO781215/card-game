extends Control

func _ready() -> void:
	GameState.apply_background($BgImage)
	GameState.apply_label_color($CenterContainer/VBoxContainer/Title)

func _on_card_query_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/CardLookup.tscn")

func _on_psych_test_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/PsychTest.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
