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
var _touch_start_x: float = 0.0
var _scroll_start: int = 0
var _is_dragging: bool = false
var _is_h_swiping: bool = false
var _swipe_determined: bool = false
var _card_page: int = 0
var _page_width: float = 0.0
var _mouse_pressed: bool = false
var _swipe_velocity: float = 0.0
var _touch_start_time: float = 0.0
var _page2_gender_btn: Button = null
var _pressed_card: Control = null
var _card_spring_back: Callable = Callable()
var _page2_date_label: Label = null
var _page2_age_label: Label = null

const BTN_HEIGHT := 68

func _ready() -> void:
	GameState.apply_background($BgImage)
	_apply_dialog_styles()
	var person: Dictionary = GameState.person_list[GameState.current_person_index]
	if not person.has("gender"):
		person["gender"] = "male"
		GameState.save_data()
	%NameLabel.text = person["name"]
	GameState.apply_label_color(%NameLabel)
	_load_birthdays()
	_update_birthday_display()
	_update_gender_button()
	_update_cards()
	_setup_swipe_area()
	var date_timer := Timer.new()
	date_timer.wait_time = 30.0
	date_timer.autostart = true
	date_timer.timeout.connect(_update_page2_center_date)
	add_child(date_timer)

# ── 性別 ─────────────────────────────────────────────

func _update_gender_button() -> void:
	var person: Dictionary = GameState.person_list[GameState.current_person_index]
	var label := "♂ 男" if person.get("gender", "male") == "male" else "♀ 女"
	%GenderToggleBtn.text = label
	if _page2_gender_btn != null:
		_page2_gender_btn.text = label

func _get_birth_lunar_year() -> int:
	# 優先從國曆生日換算，確保春節前後邊界正確
	# 例如：國曆 1990/01/15 → 仍屬己巳年(1989農曆年)，而非1990
	if _solar_year > 0:
		var r := LunarCalendar.solar_to_lunar(_solar_year, _solar_month, _solar_day)
		return r["year"]
	if _lunar_year > 0:
		return _lunar_year
	return -1

func _calc_nominal_age(today_lunar_year: int) -> int:
	# 虛歲規則：
	#   出生即為 1 歲，每過一次農曆春節（正月初一）+1
	#   公式：當前農曆年 - 出生農曆年 + 1
	#   today_lunar_year 由 solar_to_lunar(today) 取得，已自動判斷今年春節是否已過
	#   birth_lunar_year 由 solar_to_lunar(birthday) 取得，自動判斷出生時是否已過當年春節
	var birth_year := _get_birth_lunar_year()
	if birth_year <= 0:
		return -1
	return today_lunar_year - birth_year + 1

func _update_page2_center_date() -> void:
	var today := Time.get_date_dict_from_system()
	var lunar := LunarCalendar.solar_to_lunar(today["year"], today["month"], today["day"])
	if _page2_date_label != null:
		_page2_date_label.text = "%d年%d月%d號" % [lunar["year"], lunar["month"], lunar["day"]]
	if _page2_age_label != null:
		var age := _calc_nominal_age(lunar["year"])
		_page2_age_label.text = "虛歲 %d 歲" % age if age > 0 else "虛歲 --- 歲"

func _on_today_fortune_pressed() -> void:
	pass

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
	var s: float = GameState.SCALE_VALUES[GameState.ui_scale_level]
	if mode in ["solar_year", "lunar_year"]:
		panel.anchor_top = 0.1
		panel.anchor_bottom = 0.9
	elif mode in ["solar_month", "lunar_month"]:
		panel.anchor_top = 0.25
		panel.anchor_bottom = 0.25 + 0.30 * s
	else:
		panel.anchor_top = 0.25
		panel.anchor_bottom = 0.25 + 0.42 * s

	var list: GridContainer = %PickerList
	for child in list.get_children():
		child.queue_free()

	var count: int
	var current_idx: int
	var cols: int
	match mode:
		"solar_year":  count = 200; current_idx = (_solar_year - 1901) if _solar_year > 0 else (2000 - 1901); cols = 5
		"solar_month": count = 12;  current_idx = _solar_month - 1;   cols = 6
		"solar_day":
			count = _max_solar_day(_solar_year, _solar_month)
			current_idx = _solar_day - 1
			cols = 10
		"lunar_year":  count = 200; current_idx = (_lunar_year - 1901) if _lunar_year > 0 else (2000 - 1901); cols = 5
		"lunar_month": count = 12;  current_idx = _lunar_month - 1;   cols = 6
		"lunar_day":   count = 30;  current_idx = _lunar_day - 1;     cols = 10

	list.columns = cols

	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.12, 0.12, 0.12, 1.0)
	btn_style.set_corner_radius_all(4)
	btn_style.set_content_margin_all(4)

	var sc := GameState.SELECTED_COLOR
	var selected_style := StyleBoxFlat.new()
	selected_style.bg_color = Color(sc.r, sc.g, sc.b, 0.5)
	selected_style.set_corner_radius_all(4)
	selected_style.set_content_margin_all(4)

	var has_value: bool
	match mode:
		"solar_year":  has_value = _solar_year > 0
		"solar_month": has_value = _solar_month > 0
		"solar_day":   has_value = _solar_day > 0
		"lunar_year":  has_value = _lunar_year > 0
		"lunar_month": has_value = _lunar_month > 0
		"lunar_day":   has_value = _lunar_day > 0
		_:             has_value = false

	for i in range(count):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, BTN_HEIGHT)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 20)
		var is_selected := has_value and i == current_idx
		var style := selected_style if is_selected else btn_style
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("focus",  style)
		if is_selected:
			btn.add_theme_color_override("font_color", Color.WHITE)
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
	var row_h := BTN_HEIGHT + 4
	var scroll_top := row * row_h
	var center_offset := int(%PickerScroll.size.y / 2.0) - row_h / 2
	%PickerScroll.scroll_vertical = maxi(0, scroll_top - center_offset)

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
	_update_cards()
	_update_page2_center_date()
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
	var sc: ScrollContainer = $MainVBox/ScrollContainer

	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start_y = event.position.y
			_touch_start_x = event.position.x
			_touch_start_time = Time.get_ticks_msec() / 1000.0
			if %BirthdayOverlay.visible:
				_scroll_start = %PickerScroll.scroll_vertical
			else:
				_scroll_start = sc.scroll_vertical
			_is_dragging = false
			_is_h_swiping = false
			_swipe_determined = false
			_swipe_velocity = 0.0
		else:
			if _is_h_swiping:
				_snap_to_page()
				get_viewport().set_input_as_handled()
			elif _is_dragging:
				get_viewport().set_input_as_handled()

	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_mouse_pressed = true
				_touch_start_y = mb.position.y
				_touch_start_x = mb.position.x
				if %BirthdayOverlay.visible:
					_scroll_start = %PickerScroll.scroll_vertical
				else:
					_scroll_start = sc.scroll_vertical
				_is_dragging = false
				_is_h_swiping = false
				_swipe_determined = false
			else:
				_mouse_pressed = false
				if _is_h_swiping:
					_snap_to_page()
					get_viewport().set_input_as_handled()
				elif _is_dragging:
					get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion and _mouse_pressed:
		var mm := event as InputEventMouseMotion
		if %BirthdayOverlay.visible:
			var dist := absf(mm.position.y - _touch_start_y)
			if dist > 8.0:
				_is_dragging = true
			if _is_dragging:
				%PickerScroll.scroll_vertical = _scroll_start + int(_touch_start_y - mm.position.y)
				get_viewport().set_input_as_handled()
		else:
			var dx: float = mm.position.x - _touch_start_x
			var dy: float = mm.position.y - _touch_start_y
			if not _swipe_determined:
				if absf(dx) > 12.0 or absf(dy) > 8.0:
					_swipe_determined = true
					_cancel_card_press()
					_is_h_swiping = absf(dx) > absf(dy)
					if not _is_h_swiping:
						_is_dragging = true
			if _is_h_swiping:
				if _page_width > 0:
					var base_x := -_card_page * _page_width
					%CardsHBox.position.x = base_x + dx
				get_viewport().set_input_as_handled()
			elif _is_dragging:
				sc.scroll_vertical = _scroll_start + int(_touch_start_y - mm.position.y)
				get_viewport().set_input_as_handled()

	elif event is InputEventScreenDrag:
		if %BirthdayOverlay.visible:
			var dist := absf(event.position.y - _touch_start_y)
			if dist > 8.0:
				_is_dragging = true
			if _is_dragging:
				%PickerScroll.scroll_vertical = _scroll_start + int(_touch_start_y - event.position.y)
				get_viewport().set_input_as_handled()
			return

		var dx: float = event.position.x - _touch_start_x
		var dy: float = event.position.y - _touch_start_y

		if not _swipe_determined:
			if absf(dx) > 12.0 or absf(dy) > 8.0:
				_swipe_determined = true
				_cancel_card_press()
				_is_h_swiping = absf(dx) > absf(dy)
				if not _is_h_swiping:
					_is_dragging = true

		if _is_h_swiping:
			if _page_width > 0:
				var base_x := -_card_page * _page_width
				%CardsHBox.position.x = base_x + dx
			var drag_evt := event as InputEventScreenDrag
			_swipe_velocity = drag_evt.velocity.x
			get_viewport().set_input_as_handled()
		elif _is_dragging:
			sc.scroll_vertical = _scroll_start + int(_touch_start_y - event.position.y)
			get_viewport().set_input_as_handled()

# ── 分頁滑動 ──────────────────────────────────────────

func _setup_swipe_area() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var page_w: float = %SwipeArea.size.x
	if page_w <= 0:
		page_w = get_viewport().size.x
	%Page1.custom_minimum_size.x = page_w
	%Page2.custom_minimum_size.x = page_w
	_build_page2(page_w)
	await get_tree().process_frame
	var page_h: float = %Page1.size.y
	if page_h <= 0:
		page_h = %SwipeArea.size.y
	%SwipeArea.custom_minimum_size.y = page_h
	%CardsHBox.size = Vector2(page_w * 2.0, page_h)
	%CardsHBox.position = Vector2(0.0, 0.0)
	_page_width = page_w
	_update_page_indicator()
	%SwipeArea.modulate.a = 1.0
	$MainVBox/ScrollContainer/ContentVBox/PageIndicatorMargin.modulate.a = 1.0

func _go_to_page(n: int) -> void:
	_card_page = clampi(n, 0, 1)
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(%CardsHBox, "position:x", -_card_page * _page_width, 0.3)
	_update_page_indicator()

func _snap_to_page() -> void:
	if _page_width <= 0:
		return
	var dx: float = %CardsHBox.position.x - (-_card_page * _page_width)
	var elapsed: float = Time.get_ticks_msec() / 1000.0 - _touch_start_time
	var manual_vel: float = dx / max(elapsed, 0.05)
	var velocity := _swipe_velocity if absf(_swipe_velocity) > absf(manual_vel) else manual_vel
	var fast_flick := absf(velocity) > 300.0
	var far_enough := absf(dx) > _page_width * 0.25
	if far_enough or fast_flick:
		var dir := 1 if dx < 0.0 else -1
		if fast_flick and absf(dx) < 5.0:
			dir = 1 if velocity < 0.0 else -1
		_go_to_page(clampi(_card_page + dir, 0, 1))
	else:
		_go_to_page(_card_page)
	_swipe_velocity = 0.0

func _make_indicator_style(active: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(1, 1, 1, 0.75) if active else Color(0.5, 0.5, 0.5, 0.5)
	s.set_corner_radius_all(4)
	return s

func _update_page_indicator() -> void:
	%IndicatorLeft.add_theme_stylebox_override("panel",  _make_indicator_style(_card_page == 0))
	%IndicatorRight.add_theme_stylebox_override("panel", _make_indicator_style(_card_page == 1))

func _cancel_card_press() -> void:
	if _pressed_card == null:
		return
	_pressed_card = null
	if _card_spring_back.is_valid():
		_card_spring_back.call()
	_card_spring_back = Callable()

func _attach_card_press_anim(node: Control) -> void:
	node.mouse_filter = Control.MOUSE_FILTER_STOP
	node.resized.connect(func(): node.pivot_offset = node.size / 2.0)
	var _tween: Tween = null
	var _is_pressed := false

	var spring_back := func():
		_is_pressed = false
		if _tween:
			_tween.kill()
		_tween = node.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SPRING)
		_tween.tween_property(node, "scale", Vector2(1.0, 1.0), 0.45)

	node.mouse_exited.connect(func():
		if _is_pressed:
			_pressed_card = null
			_card_spring_back = Callable()
			spring_back.call()
	)

	node.gui_input.connect(func(event: InputEvent):
		var pressed := false
		var relevant := false
		if event is InputEventScreenTouch:
			pressed = event.pressed; relevant = true
		elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			pressed = event.pressed; relevant = true
		if not relevant:
			return
		if pressed:
			_is_pressed = true
			_pressed_card = node
			_card_spring_back = spring_back
			if _tween:
				_tween.kill()
			_tween = node.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			_tween.tween_property(node, "scale", Vector2(0.88, 0.88), 0.08)
		else:
			_is_pressed = false
			_pressed_card = null
			_card_spring_back = Callable()
			spring_back.call()
	)

func _make_page2_panel(code: String, skin: String, style: StyleBoxFlat, lbl: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)
	var card := TextureRect.new()
	card.custom_minimum_size = Vector2(72, 140)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.texture = CardCalc.get_card_texture_for_skin(code, skin)
	vbox.add_child(card)
	var label := Label.new()
	label.text = lbl
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 13)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)
	_attach_card_press_anim(card)
	return panel

func _build_page2_center_info() -> Control:
	var today := Time.get_date_dict_from_system()
	var lunar := LunarCalendar.solar_to_lunar(today["year"], today["month"], today["day"])

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vbox.add_theme_constant_override("separation", 10)

	var lbl_title := Label.new()
	lbl_title.text = "今天是農曆"
	lbl_title.add_theme_color_override("font_color", Color.WHITE)
	lbl_title.add_theme_font_size_override("font_size", 24)
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_title)

	var lbl_date := Label.new()
	lbl_date.add_theme_color_override("font_color", Color.WHITE)
	lbl_date.add_theme_font_size_override("font_size", 24)
	lbl_date.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_date)
	_page2_date_label = lbl_date

	var lbl_age := Label.new()
	lbl_age.add_theme_color_override("font_color", Color.WHITE)
	lbl_age.add_theme_font_size_override("font_size", 24)
	lbl_age.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_age)
	_page2_age_label = lbl_age

	_update_page2_center_date()

	var fortune_btn := Button.new()
	fortune_btn.text = "今日運勢"
	fortune_btn.add_theme_font_size_override("font_size", 20)
	fortune_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	fortune_btn.custom_minimum_size = Vector2(150, 0)
	fortune_btn.pressed.connect(_on_today_fortune_pressed)
	vbox.add_child(fortune_btn)

	return vbox

func _build_page2(page_w: float) -> void:
	var page2 := %Page2
	page2.visible = true
	for child in page2.get_children():
		child.queue_free()

	var top_pad := Control.new()
	top_pad.custom_minimum_size = Vector2(0, 60)
	page2.add_child(top_pad)

	var page2_skin := "cardskin4" if GameState.card_skin == "cardskin4" else "cardskin3"

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0, 0, 0, 0.55)
	panel_style.set_corner_radius_all(4)
	panel_style.set_content_margin_all(4)

	# 左右 pad 吸收多餘空間，讓 rows 固定在最小寬度（同 Page1 的 BlueLeftPad/RightPad 做法）
	var grid_hbox := HBoxContainer.new()
	grid_hbox.add_theme_constant_override("separation", 0)
	grid_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page2.add_child(grid_hbox)

	var grid_left_pad := Control.new()
	grid_left_pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_hbox.add_child(grid_left_pad)

	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 6)
	rows.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid_hbox.add_child(rows)

	var grid_right_pad := Control.new()
	grid_right_pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_hbox.add_child(grid_right_pad)

	# 第一行：巳午未申
	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 6)
	rows.add_child(row1)
	for code in ["GG", "PK", "RQ", "BB"]:
		row1.add_child(_make_page2_panel(code, page2_skin, panel_style, "1~10歲"))

	# 中段：左欄(辰卯) | 中央資訊 | 右欄(酉戌)
	var mid := HBoxContainer.new()
	mid.add_theme_constant_override("separation", 6)
	rows.add_child(mid)

	var left_col := VBoxContainer.new()
	left_col.add_theme_constant_override("separation", 6)
	left_col.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	mid.add_child(left_col)
	left_col.add_child(_make_page2_panel("BQ", page2_skin, panel_style, "1~10歲"))
	left_col.add_child(_make_page2_panel("RK", page2_skin, panel_style, "1~10歲"))

	mid.add_child(_build_page2_center_info())

	var right_col := VBoxContainer.new()
	right_col.add_theme_constant_override("separation", 6)
	right_col.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	mid.add_child(right_col)
	right_col.add_child(_make_page2_panel("GK", page2_skin, panel_style, "1~10歲"))
	right_col.add_child(_make_page2_panel("PQ", page2_skin, panel_style, "1~10歲"))

	# 第四行：寅丑子亥
	var row4 := HBoxContainer.new()
	row4.add_theme_constant_override("separation", 6)
	rows.add_child(row4)
	for code in ["PB", "GQ", "BK", "RG"]:
		row4.add_child(_make_page2_panel(code, page2_skin, panel_style, "1~10歲"))

	var row_spacer := Control.new()
	row_spacer.custom_minimum_size = Vector2(0, 12)
	page2.add_child(row_spacer)

	# 底部列：同樣用左右 pad 包住
	var bottom_hbox_outer := HBoxContainer.new()
	bottom_hbox_outer.add_theme_constant_override("separation", 0)
	bottom_hbox_outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page2.add_child(bottom_hbox_outer)

	var bottom_left_pad := Control.new()
	bottom_left_pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_hbox_outer.add_child(bottom_left_pad)

	var bottom_hbox := HBoxContainer.new()
	bottom_hbox.add_theme_constant_override("separation", 6)
	bottom_hbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bottom_hbox_outer.add_child(bottom_hbox)

	var bottom_right_pad := Control.new()
	bottom_right_pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_hbox_outer.add_child(bottom_right_pad)

	for bl in ["十年大運", "流年", "流月", "流日"]:
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", panel_style)
		panel.custom_minimum_size = Vector2(72, 0)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 2)
		panel.add_child(vbox)
		var card := TextureRect.new()
		card.custom_minimum_size = Vector2(72, 106)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.texture = CardCalc.get_card_texture_for_skin("BK", page2_skin)
		vbox.add_child(card)
		var label := Label.new()
		label.text = bl
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_font_size_override("font_size", 12)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(label)
		_attach_card_press_anim(card)
		bottom_hbox.add_child(panel)

	var bottom_pad := Control.new()
	bottom_pad.custom_minimum_size = Vector2(0, 60)
	page2.add_child(bottom_pad)

func _fit_center_card(card: TextureRect) -> void:
	var tex := card.texture
	if tex == null:
		card.custom_minimum_size.y = 190
		return
	var ratio := float(tex.get_height()) / float(tex.get_width())
	card.custom_minimum_size.y = ceili(96.0 * ratio)

func _update_cards() -> void:
	if _solar_year == 0:
		%NCZ_Card.texture = null
		%LCZ_Card.texture = null
		%NWZ_Card.texture = null
		%LWZ_Card.texture = null
		%NUN_Card.texture = null
		%NLN_Card.texture = null
		%LUN_Card.texture = null
		%LLN_Card.texture = null
		return
	var solar_animal := CardCalc.get_chinese_zodiac(_solar_year)
	%NCZ_Card.texture = CardCalc.get_cz_card_texture(solar_animal)
	var lunar_animal := CardCalc.get_chinese_zodiac(_lunar_year)
	%LCZ_Card.texture = CardCalc.get_cz_card_texture(lunar_animal)
	var solar_sign := CardCalc.get_western_zodiac(_solar_month, _solar_day)
	%NWZ_Card.texture = CardCalc.get_wz_card_texture(solar_sign)
	var lunar_sign := CardCalc.get_western_zodiac(_lunar_month, _lunar_day)
	%LWZ_Card.texture = CardCalc.get_wz_card_texture(lunar_sign)
	var solar_lpn := CardCalc.get_life_path_number(_solar_year, _solar_month, _solar_day)
	%NUN_Card.texture = CardCalc.get_lpn_upper_texture(solar_lpn)
	_fit_center_card(%NUN_Card)
	%NLN_Card.texture = CardCalc.get_lpn_lower_texture(solar_lpn)
	_fit_center_card(%NLN_Card)
	var lunar_lpn := CardCalc.get_life_path_number(_lunar_year, _lunar_month, _lunar_day)
	%LUN_Card.texture = CardCalc.get_lpn_upper_texture(lunar_lpn)
	_fit_center_card(%LUN_Card)
	%LLN_Card.texture = CardCalc.get_lpn_lower_texture(lunar_lpn)
	_fit_center_card(%LLN_Card)

func _apply_dialog_styles() -> void:
	for panel in [$BirthdayOverlay/PickerPanel, $RenameOverlay/RenamePanel]:
		panel.add_theme_stylebox_override("panel", GameState.make_dialog_stylebox())
		GameState.apply_dialog_btn_styles(panel)
	$RenameOverlay/RenamePanel/RenameMargin/RenameVBox/RenameLabel.add_theme_color_override("font_color", GameState.DIALOG_TITLE_COLOR)

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
