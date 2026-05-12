extends Node

var background_enabled: bool = true
var ui_scale_level: int = -1
var person_list: Array = [{"name": "新聊遇"}]
var current_person_index: int = 0
const MAX_PERSONS: int = 99

const SCALE_VALUES: Array = [0.6, 0.75, 1.0, 1.35]
const SCALE_NAMES: Array = ["小", "中", "大", "很大"]

const SAVE_PATH = "user://save_data.json"

func _ready() -> void:
	load_data()
	if ui_scale_level == -1:
		_auto_detect_scale()
	apply_ui_scale()

func save_data() -> void:
	var data := {
		"person_list": person_list,
		"ui_scale_level": ui_scale_level,
		"background_enabled": background_enabled
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return
	var data = json.get_data()
	if data.has("person_list"):
		person_list = data["person_list"]
	if data.has("ui_scale_level"):
		ui_scale_level = data["ui_scale_level"]
	if data.has("background_enabled"):
		background_enabled = data["background_enabled"]

func _auto_detect_scale() -> void:
	var dpi := DisplayServer.screen_get_dpi()
	if dpi <= 0:
		ui_scale_level = 1
	elif dpi > 480:
		ui_scale_level = 3
	elif dpi > 360:
		ui_scale_level = 2
	elif dpi > 240:
		ui_scale_level = 1
	else:
		ui_scale_level = 0

func apply_ui_scale() -> void:
	get_tree().root.content_scale_factor = SCALE_VALUES[ui_scale_level]

func apply_background(bg_image: TextureRect) -> void:
	bg_image.visible = background_enabled

func apply_label_color(label: Label) -> void:
	label.add_theme_color_override("font_color", Color.WHITE if background_enabled else Color.BLACK)
