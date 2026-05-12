extends Control

var _long_press_timer: Timer
var _touch_start_y: float = 0.0
var _scroll_start: int = 0
var _long_press_index: int = -1
var _is_long_press: bool = false

func _ready() -> void:
	GameState.apply_background($BgImage)
	GameState.apply_label_color($MarginContainer/VBoxContainer/Title)

	_long_press_timer = Timer.new()
	_long_press_timer.wait_time = 0.6
	_long_press_timer.one_shot = true
	_long_press_timer.timeout.connect(_on_long_press_timeout)
	add_child(_long_press_timer)

	_rebuild_grid()

func _rebuild_grid() -> void:
	var grid := %GridContainer
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()

	for i in range(GameState.person_list.size()):
		var btn := Button.new()
		btn.text = GameState.person_list[i]["name"]
		btn.custom_minimum_size = Vector2(0, 90)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 20)
		var idx := i
		btn.pressed.connect(func(): _on_person_pressed(idx))
		btn.button_down.connect(func(): _start_long_press(idx))
		btn.button_up.connect(_cancel_long_press)
		grid.add_child(btn)

	if GameState.person_list.size() < GameState.MAX_PERSONS:
		var add_btn := Button.new()
		add_btn.text = "+"
		add_btn.custom_minimum_size = Vector2(0, 90)
		add_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_btn.add_theme_font_size_override("font_size", 36)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(1, 1, 1, 0.05)
		style.border_color = Color(0.5, 0.5, 0.5, 1)
		style.set_border_width_all(3)
		style.set_corner_radius_all(6)
		style.set_content_margin_all(8)
		add_btn.add_theme_stylebox_override("normal", style)
		var hover_style := style.duplicate()
		hover_style.bg_color = Color(0.85, 0.85, 0.85, 1)
		add_btn.add_theme_stylebox_override("hover", hover_style)
		add_btn.add_theme_stylebox_override("pressed", hover_style)
		add_btn.pressed.connect(_on_add_pressed)
		grid.add_child(add_btn)

func _start_long_press(idx: int) -> void:
	_is_long_press = false
	_long_press_index = idx
	_long_press_timer.start()

func _cancel_long_press() -> void:
	_long_press_timer.stop()

func _on_long_press_timeout() -> void:
	_is_long_press = true
	%OptionsOverlay.visible = true

func _on_person_pressed(idx: int) -> void:
	if _is_long_press:
		_is_long_press = false
		return
	GameState.current_person_index = idx
	get_tree().change_scene_to_file("res://scenes/PersonCard.tscn")

func _on_add_pressed() -> void:
	GameState.person_list.append({"name": "新聊遇"})
	GameState.save_data()
	_rebuild_grid()

func _on_move_btn_pressed() -> void:
	%OptionsOverlay.visible = false
	var total := GameState.person_list.size()
	(%MoveLabel as Label).text = "移動到第幾號位置？（1 - %d）" % total
	(%MoveInput as LineEdit).text = str(_long_press_index + 1)
	%MoveOverlay.visible = true

func _on_confirm_move_pressed() -> void:
	var input_text: String = (%MoveInput as LineEdit).text.strip_edges()
	if input_text.is_valid_int():
		var dest: int = input_text.to_int() - 1
		var total := GameState.person_list.size()
		dest = clampi(dest, 0, total - 1)
		if dest != _long_press_index:
			var person = GameState.person_list[_long_press_index]
			GameState.person_list.remove_at(_long_press_index)
			GameState.person_list.insert(dest, person)
			GameState.save_data()
	%MoveOverlay.visible = false
	_rebuild_grid()

func _on_cancel_move_pressed() -> void:
	%MoveOverlay.visible = false

func _on_rename_btn_pressed() -> void:
	%OptionsOverlay.visible = false
	(%RenameInput as LineEdit).text = GameState.person_list[_long_press_index]["name"]
	%RenameOverlay.visible = true

func _on_delete_btn_pressed() -> void:
	%OptionsOverlay.visible = false
	%DeleteOverlay.visible = true

func _on_options_cancel_pressed() -> void:
	%OptionsOverlay.visible = false

func _on_confirm_rename_pressed() -> void:
	var new_name: String = (%RenameInput as LineEdit).text.strip_edges()
	if new_name.length() > 0:
		GameState.person_list[_long_press_index]["name"] = new_name
		GameState.save_data()
	%RenameOverlay.visible = false
	_rebuild_grid()

func _on_cancel_rename_pressed() -> void:
	%RenameOverlay.visible = false

func _on_confirm_delete_pressed() -> void:
	GameState.person_list.remove_at(_long_press_index)
	GameState.save_data()
	%DeleteOverlay.visible = false
	_rebuild_grid()

func _on_cancel_delete_pressed() -> void:
	%DeleteOverlay.visible = false

func _unhandled_input(event: InputEvent) -> void:
	var sc: ScrollContainer = $MarginContainer/VBoxContainer/PanelContainer/ScrollContainer
	if event is InputEventScreenTouch and event.pressed:
		_touch_start_y = event.position.y
		_scroll_start = sc.scroll_vertical
	elif event is InputEventScreenDrag:
		sc.scroll_vertical = _scroll_start + int(_touch_start_y - event.position.y)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
