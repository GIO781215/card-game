extends Control

var _solar_year: int = 2000
var _solar_month: int = 1
var _solar_day: int = 1
var _lunar_year: int = 2000
var _lunar_month: int = 1
var _lunar_day: int = 1
var _picker_mode: String = ""
var _sequential_mode: bool = false
var _sequential_start: String = ""
var _touch_start_y: float = 0.0
var _scroll_start: int = 0
var _is_dragging: bool = false

const BTN_HEIGHT := 68

func _ready() -> void:
	GameState.apply_background($BgImage)
	var person: Dictionary = GameState.person_list[GameState.current_person_index]
	if not person.has("gender"):
		person["gender"] = "male"
		GameState.save_data()
	%NameLabel.text = person["name"]
	GameState.apply_label_color(%NameLabel)
	_load_birthdays()
	_update_birthday_display()
	_update_gender_button()

# ── 性別 ─────────────────────────────────────────────

func _update_gender_button() -> void:
	var person: Dictionary = GameState.person_list[GameState.current_person_index]
	%GenderToggleBtn.text = "♂ 男" if person.get("gender", "male") == "male" else "♀ 女"

func _on_gender_toggle_pressed() -> void:
	var person: Dictionary = GameState.person_list[GameState.current_person_index]
	person["gender"] = "female" if person.get("gender", "male") == "male" else "male"
	GameState.save_data()
	_update_gender_button()

# ── 生日資料 ──────────────────────────────────────────

func _max_solar_day(year: int, month: int) -> int:
	var days := [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	if month == 2:
		var leap := (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0)
		return 29 if leap else 28
	return days[month - 1]

func _load_birthdays() -> void:
	var person: Dictionary = GameState.person_list[GameState.current_person_index]
	_parse_date(person.get("birthday_solar", ""), true)
	_parse_date(person.get("birthday_lunar", ""), false)

func _parse_date(date_str: String, is_solar: bool) -> void:
	var parts := date_str.split("/")
	if parts.size() == 3 and parts[0].is_valid_int() and parts[1].is_valid_int() and parts[2].is_valid_int():
		var y := parts[0].to_int()
		var m := clampi(parts[1].to_int(), 1, 12)
		var d := parts[2].to_int()
		if is_solar:
			_solar_year = clampi(y, 1901, 2100); _solar_month = m
			_solar_day = clampi(d, 1, _max_solar_day(y, m))
		else:
			_lunar_year = clampi(y, 1901, 2100); _lunar_month = m
			_lunar_day = clampi(d, 1, 30)
	else:
		if is_solar:
			_solar_year = 0; _solar_month = 0; _solar_day = 0
		else:
			_lunar_year = 0; _lunar_month = 0; _lunar_day = 0

func _update_birthday_display() -> void:
	%SolarYearBtn.text  = ("---- 年" if _solar_year  == 0 else str(_solar_year)  + " 年")
	%SolarMonthBtn.text = ("-- 月"   if _solar_month == 0 else str(_solar_month) + " 月")
	%SolarDayBtn.text   = ("-- 日"   if _solar_day   == 0 else str(_solar_day)   + " 日")
	%LunarYearBtn.text  = ("---- 年" if _lunar_year  == 0 else str(_lunar_year)  + " 年")
	%LunarMonthBtn.text = ("-- 月"   if _lunar_month == 0 else str(_lunar_month) + " 月")
	%LunarDayBtn.text   = ("-- 日"   if _lunar_day   == 0 else str(_lunar_day)   + " 日")

func _save_birthdays() -> void:
	var person: Dictionary = GameState.person_list[GameState.current_person_index]
	person["birthday_solar"] = "" if _solar_year == 0 else "%04d/%02d/%02d" % [_solar_year, _solar_month, _solar_day]
	person["birthday_lunar"] = "" if _lunar_year == 0 else "%04d/%02d/%02d" % [_lunar_year, _lunar_month, _lunar_day]
	GameState.save_data()

# ── 選擇器 ────────────────────────────────────────────

func _show_picker(mode: String) -> void:
	_picker_mode = mode

	var panel := $BirthdayOverlay/PickerPanel
	if mode in ["solar_year", "lunar_year"]:
		panel.anchor_top = 0.1
		panel.anchor_bottom = 0.9
	else:
		panel.anchor_top = 0.25
		panel.anchor_bottom = 0.72

	var list: GridContainer = %PickerList
	for child in list.get_children():
		child.queue_free()

	var count: int
	var current_idx: int
	var cols: int
	match mode:
		"solar_year":  count = 200; current_idx = _solar_year - 1901; cols = 5
		"solar_month": count = 12;  current_idx = _solar_month - 1;   cols = 6
		"solar_day":
			count = _max_solar_day(_solar_year, _solar_month)
			current_idx = _solar_day - 1
			cols = 10
		"lunar_year":  count = 200; current_idx = _lunar_year - 1901; cols = 5
		"lunar_month": count = 12;  current_idx = _lunar_month - 1;   cols = 6
		"lunar_day":   count = 30;  current_idx = _lunar_day - 1;     cols = 10

	list.columns = cols

	for i in range(count):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, BTN_HEIGHT)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 20)
		match mode:
			"solar_year", "lunar_year":     btn.text = str(1901 + i)
			"solar_month", "lunar_month":   btn.text = str(i + 1) + " 月"
			"solar_day", "lunar_day":       btn.text = str(i + 1)
		var idx := i
		btn.pressed.connect(func(): if not _is_dragging: _on_picker_selected(idx))
		list.add_child(btn)

	%BirthdayOverlay.visible = true
	await get_tree().process_frame
	var row := current_idx / cols
	%PickerScroll.scroll_vertical = row * (BTN_HEIGHT + 4)

func _on_picker_selected(idx: int) -> void:
	match _picker_mode:
		"solar_year":
			_solar_year = 1901 + idx
			if _solar_day > 0:
				_solar_day = clampi(_solar_day, 1, _max_solar_day(_solar_year, _solar_month))
		"solar_month":
			_solar_month = idx + 1
			if _solar_day > 0:
				_solar_day = clampi(_solar_day, 1, _max_solar_day(_solar_year, _solar_month))
		"solar_day":   _solar_day = idx + 1
		"lunar_year":  _lunar_year = 1901 + idx
		"lunar_month":
			_lunar_month = idx + 1
			if _lunar_day > 0:
				_lunar_day = clampi(_lunar_day, 1, 30)
		"lunar_day":   _lunar_day = idx + 1

	if _sequential_mode:
		var next := _next_sequential_picker(_picker_mode)
		if next != "":
			_show_picker(next)
			return

	_sequential_mode = false
	if _picker_mode.begins_with("solar"):
		_sync_lunar_from_solar()
	else:
		_sync_solar_from_lunar()
	_save_birthdays()
	_update_birthday_display()
	%BirthdayOverlay.visible = false

func _sync_lunar_from_solar() -> void:
	if _solar_year == 0:
		return
	var r: Dictionary = LunarCalendar.solar_to_lunar(_solar_year, _solar_month, _solar_day)
	_lunar_year = r["year"]
	_lunar_month = r["month"]
	_lunar_day = r["day"]

func _sync_solar_from_lunar() -> void:
	if _lunar_year == 0:
		return
	var r: Dictionary = LunarCalendar.lunar_to_solar(_lunar_year, _lunar_month, _lunar_day)
	_solar_year = r["year"]
	_solar_month = r["month"]
	_solar_day = r["day"]

func _on_solar_year_pressed() -> void:  _open_picker("solar_year")
func _on_solar_month_pressed() -> void: _open_picker("solar_month")
func _on_solar_day_pressed() -> void:   _open_picker("solar_day")
func _on_lunar_year_pressed() -> void:  _open_picker("lunar_year")
func _on_lunar_month_pressed() -> void: _open_picker("lunar_month")
func _on_lunar_day_pressed() -> void:   _open_picker("lunar_day")

func _open_picker(mode: String) -> void:
	var calendar := mode.split("_")[0]
	var is_unset := (_solar_year == 0) if calendar == "solar" else (_lunar_year == 0)
	if is_unset:
		_sequential_mode = true
		_sequential_start = mode.split("_")[1]
	else:
		_sequential_mode = false
	_show_picker(mode)

func _next_sequential_picker(current_mode: String) -> String:
	var calendar := current_mode.split("_")[0]
	var part    := current_mode.split("_")[1]
	var sequences := {
		"year":  ["year", "month", "day"],
		"month": ["month", "day", "year"],
		"day":   ["day", "year", "month"],
	}
	var seq: Array = sequences[_sequential_start]
	var i := seq.find(part)
	if i >= 0 and i < seq.size() - 1:
		return calendar + "_" + seq[i + 1]
	return ""

func _on_picker_cancel_pressed() -> void:
	%BirthdayOverlay.visible = false

# ── 觸控滑動 ──────────────────────────────────────────

func _input(event: InputEvent) -> void:
	var sc: ScrollContainer
	if %BirthdayOverlay.visible:
		sc = %PickerScroll
	else:
		sc = $MainVBox/ScrollContainer
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start_y = event.position.y
			_scroll_start = sc.scroll_vertical
			_is_dragging = false
		else:
			if _is_dragging:
				get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var dist := absf(event.position.y - _touch_start_y)
		if dist > 8.0:
			_is_dragging = true
		if _is_dragging:
			sc.scroll_vertical = _scroll_start + int(_touch_start_y - event.position.y)
			get_viewport().set_input_as_handled()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/CardLookup.tscn")

# ── 改名 ──────────────────────────────────────────────

func _on_name_label_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_show_rename()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_show_rename()

func _show_rename() -> void:
	var person: Dictionary = GameState.person_list[GameState.current_person_index]
	%RenameInput.text = person["name"]
	%RenameOverlay.visible = true
	%RenameInput.grab_focus()
	%RenameInput.select_all()

func _on_confirm_rename_pressed() -> void:
	var new_name: String = %RenameInput.text.strip_edges()
	if new_name.length() > 0:
		var person: Dictionary = GameState.person_list[GameState.current_person_index]
		person["name"] = new_name
		GameState.save_data()
		%NameLabel.text = new_name
	%RenameOverlay.visible = false

func _on_cancel_rename_pressed() -> void:
	%RenameOverlay.visible = false
