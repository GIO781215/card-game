extends Node

var background_enabled: bool = true
var ui_scale_level: int = -1

const SCALE_VALUES: Array = [0.6, 0.75, 1.0, 1.35]
const SCALE_NAMES: Array = ["小", "中", "大", "很大"]

func _ready() -> void:
	if ui_scale_level == -1:
		_auto_detect_scale()
	apply_ui_scale()

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
