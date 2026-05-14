extends Node

var background_enabled: bool = true
var ui_scale_level: int = 1
var card_skin: String = "cardskin1"
var person_list: Array = [{"name": "新聊遇"}]
var current_person_index: int = 0
const MAX_PERSONS: int = 99

const SCALE_VALUES: Array = [0.6, 0.75, 1.0]
const SCALE_NAMES: Array = ["小", "中", "大"]

const SAVE_PATH = "user://save_data.json"

# 全域選中按鈕顏色，調整這裡即可統一變更
const SELECTED_COLOR := Color(0.0, 0.792, 0.792)

# 全域對話框配色，調整這裡即可統一變更
const DIALOG_BG_COLOR      := Color(0.0,  0.0,  0.0,  1.0)
const DIALOG_TITLE_COLOR   := Color(1.0,  1.0,  1.0,  1.0)
const DIALOG_TEXT_COLOR    := Color(0.85, 0.85, 0.85, 1.0)
const DIALOG_BTN_COLOR     := Color(0.22, 0.22, 0.22, 1.0)
const DIALOG_CORNER_RADIUS := 12

func make_dialog_stylebox() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = DIALOG_BG_COLOR
	s.set_corner_radius_all(DIALOG_CORNER_RADIUS)
	return s

func apply_dialog_btn_styles(root: Node) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = DIALOG_BTN_COLOR
	s.set_corner_radius_all(6)
	s.set_content_margin_all(8)
	var h := s.duplicate() as StyleBoxFlat
	h.bg_color = Color(DIALOG_BTN_COLOR.r + 0.15, DIALOG_BTN_COLOR.g + 0.15, DIALOG_BTN_COLOR.b + 0.15, 1.0)
	for child in root.get_children():
		if child is Button:
			child.add_theme_stylebox_override("normal",  s)
			child.add_theme_stylebox_override("focus",   s)
			child.add_theme_stylebox_override("hover",   h)
			child.add_theme_stylebox_override("pressed", h)
		apply_dialog_btn_styles(child)

func _ready() -> void:
	load_data()
	apply_ui_scale()

func save_data() -> void:
	var data := {
		"person_list": person_list,
		"ui_scale_level": ui_scale_level,
		"background_enabled": background_enabled,
		"card_skin": card_skin,
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
		ui_scale_level = clampi(data["ui_scale_level"], 0, 2)
	if data.has("background_enabled"):
		background_enabled = data["background_enabled"]
	if data.has("card_skin"):
		card_skin = data["card_skin"]


func apply_ui_scale() -> void:
	get_tree().root.content_scale_factor = SCALE_VALUES[ui_scale_level]

func apply_background(bg_image: TextureRect) -> void:
	bg_image.visible = background_enabled

func label_color() -> Color:
	return Color.WHITE if background_enabled else Color.BLACK

func apply_label_color(label: Label) -> void:
	label.add_theme_color_override("font_color", label_color())
