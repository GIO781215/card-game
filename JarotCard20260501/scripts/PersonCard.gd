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
var _peak_swipe_dx: float = 0.0
var _swipe_commit_x: float = 0.0
var _last_drag_x: float = 0.0
var _page2_gender_btn: Button = null
var _pressed_card: Control = null
var _card_spring_back: Callable = Callable()
var _page2_date_label: Label = null
var _page2_age_label: Label = null
var _scroll_velocity: float = 0.0
var _prev_drag_y: float = 0.0
var _prev_drag_time: float = 0.0
var _inertia_sc: ScrollContainer = null
var _fortune_layer: int = 1
var _decade_code: String = ""
var _decade_start_age: int = 0
var _year_code: String = ""
var _year_display_card: String = ""
var _year_label: String = ""
var _month_code: String = ""
var _month_display_card: String = ""
var _month_label: String = ""
var _day_code: String = ""
var _day_display_card: String = ""
var _day_label: String = ""

const BTN_HEIGHT := 68

# 12宮格順時針順序（從寅出發）
const _GRID_CLOCKWISE: Array = ["PB","RK","BQ","GG","PK","RQ","BB","GK","PQ","RG","BK","GQ"]
# 生肖 → 順時針索引
const _ZODIAC_IDX: Dictionary = {
	"虎":0,"兔":1,"龍":2,"蛇":3,"馬":4,"羊":5,
	"猴":6,"雞":7,"狗":8,"豬":9,"鼠":10,"牛":11
}

func _ready() -> void:
	GameState.apply_background($BgImage)
	_apply_dialog_styles()
	var person: Dictionary = GameState.person_list[GameState.current_person_index]
	if not person.has("gender"):
		person["gender"] = "male"
		GameState.save_data()
	%NameLabel.text = person["name"]
	GameState.apply_label_color(%NameLabel)
	GameState.apply_label_color(%SolarTitle)
	GameState.apply_label_color(%LunarTitle)
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

func _process(delta: float) -> void:
	if _inertia_sc == null or absf(_scroll_velocity) < 30.0:
		_scroll_velocity = 0.0
		_inertia_sc = null
		return
	_inertia_sc.scroll_vertical += int(_scroll_velocity * delta)
	_scroll_velocity *= pow(0.1, delta)

func _track_scroll_velocity(y: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var dt := now - _prev_drag_time
	if dt > 0.005:
		_scroll_velocity = lerpf(_scroll_velocity, (_prev_drag_y - y) / dt, 0.5)
		_prev_drag_y = y
		_prev_drag_time = now

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
	if _page_width > 0:
		_build_page2(_page_width)

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
	_fortune_layer = 1
	_decade_code = ""; _decade_start_age = 0
	_year_code = ""; _year_display_card = ""; _year_label = ""
	_month_code = ""; _month_display_card = ""; _month_label = ""
	_day_code = ""; _day_display_card = ""; _day_label = ""
	if _page_width > 0:
		_build_page2(_page_width)
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
			_peak_swipe_dx = 0.0
			_last_drag_x = 0.0
			_scroll_velocity = 0.0
			_inertia_sc = null
			_prev_drag_y = event.position.y
			_prev_drag_time = Time.get_ticks_msec() / 1000.0
		else:
			if _is_h_swiping:
				var travel: float = _last_drag_x - _swipe_commit_x
				if absf(travel) >= 22.0:
					var dir := 1 if travel < 0.0 else -1
					_go_to_page(clampi(_card_page + dir, 0, 1))
				else:
					_go_to_page(_card_page)
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
				_scroll_velocity = 0.0
				_inertia_sc = null
				_prev_drag_y = mb.position.y
				_prev_drag_time = Time.get_ticks_msec() / 1000.0
			else:
				_mouse_pressed = false
				if _is_h_swiping:
					var travel: float = _last_drag_x - _swipe_commit_x
					if absf(travel) >= 22.0:
						var dir := 1 if travel < 0.0 else -1
						_go_to_page(clampi(_card_page + dir, 0, 1))
					else:
						_go_to_page(_card_page)
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
				_track_scroll_velocity(mm.position.y)
				_inertia_sc = %PickerScroll
				get_viewport().set_input_as_handled()
		else:
			var dx: float = mm.position.x - _touch_start_x
			var dy: float = mm.position.y - _touch_start_y
			if not _swipe_determined:
				if absf(dx) > 2.0 or absf(dy) > 2.0:
					_swipe_determined = true
					_cancel_card_press()
					_is_h_swiping = absf(dx) > absf(dy)
					if _is_h_swiping:
						_swipe_commit_x = mm.position.x
					else:
						_is_dragging = true
			if _is_h_swiping:
				_last_drag_x = mm.position.x
				if _page_width > 0:
					var base_x := -_card_page * _page_width
					%CardsHBox.position.x = base_x + dx
				get_viewport().set_input_as_handled()
			elif _is_dragging:
				sc.scroll_vertical = _scroll_start + int(_touch_start_y - mm.position.y)
				_track_scroll_velocity(mm.position.y)
				_inertia_sc = sc
				get_viewport().set_input_as_handled()

	elif event is InputEventScreenDrag:
		if %BirthdayOverlay.visible:
			var dist := absf(event.position.y - _touch_start_y)
			if dist > 8.0:
				_is_dragging = true
			if _is_dragging:
				%PickerScroll.scroll_vertical = _scroll_start + int(_touch_start_y - event.position.y)
				_track_scroll_velocity(event.position.y)
				_inertia_sc = %PickerScroll
				get_viewport().set_input_as_handled()
			return

		var dx: float = event.position.x - _touch_start_x
		var dy: float = event.position.y - _touch_start_y

		if not _swipe_determined:
			if absf(dx) > 2.0 or absf(dy) > 2.0:
				_swipe_determined = true
				_cancel_card_press()
				_is_h_swiping = absf(dx) > absf(dy)
				if _is_h_swiping:
					_swipe_commit_x = event.position.x
				else:
					_is_dragging = true

		if _is_h_swiping:
			_last_drag_x = event.position.x
			if _page_width > 0:
				var base_x := -_card_page * _page_width
				%CardsHBox.position.x = base_x + dx
			get_viewport().set_input_as_handled()
		elif _is_dragging:
			sc.scroll_vertical = _scroll_start + int(_touch_start_y - event.position.y)
			_track_scroll_velocity(event.position.y)
			_inertia_sc = sc
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
	await get_tree().process_frame
	var page_h: float = maxf(%Page1.size.y, %Page2.size.y)
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
	# 用滑動過程中的峰值位移判斷，避免 Android 放手前最後一個 drag 事件回縮導致誤判
	var peak := _peak_swipe_dx if absf(_peak_swipe_dx) > absf(dx) else dx
	var elapsed: float = Time.get_ticks_msec() / 1000.0 - _touch_start_time
	var manual_vel: float = peak / max(elapsed, 0.05)
	var velocity := _swipe_velocity if absf(_swipe_velocity) > absf(manual_vel) else manual_vel
	var fast_flick := absf(velocity) > 50.0
	var far_enough := absf(peak) > 12.0
	if far_enough or fast_flick:
		var dir := 1 if peak < 0.0 else -1
		_go_to_page(clampi(_card_page + dir, 0, 1))
	else:
		_go_to_page(_card_page)
	_swipe_velocity = 0.0
	_peak_swipe_dx = 0.0

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

func _attach_card_press_anim(node: Control, on_tap: Callable = Callable()) -> void:
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
			if on_tap.is_valid() and not _is_dragging:
				on_tap.call()
	)

func _make_page2_panel(code: String, skin: String, style: StyleBoxFlat, lbl: String, card_code: String = "", on_tap: Callable = Callable()) -> PanelContainer:
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
	var actual_code := card_code if card_code != "" else code
	card.texture = CardCalc.get_card_texture_for_skin(actual_code, skin)
	vbox.add_child(card)
	var label := Label.new()
	label.text = lbl
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_font_size_override("font_size", 13)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)
	_attach_card_press_anim(card, on_tap)
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
	lbl_title.add_theme_color_override("font_color", GameState.label_color())
	lbl_title.add_theme_font_size_override("font_size", 24)
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_title)

	var lbl_date := Label.new()
	lbl_date.add_theme_color_override("font_color", GameState.label_color())
	lbl_date.add_theme_font_size_override("font_size", 24)
	lbl_date.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_date)
	_page2_date_label = lbl_date

	var lbl_age := Label.new()
	lbl_age.add_theme_color_override("font_color", GameState.label_color())
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

func _get_is_male() -> bool:
	var person: Dictionary = GameState.person_list[GameState.current_person_index]
	return person.get("gender", "male") == "male"

func _calc_decade_config() -> Dictionary:
	# code → {label, start_age}
	var config: Dictionary = {}
	if _lunar_year == 0 or _lunar_month == 0:
		for code in _GRID_CLOCKWISE:
			config[code] = {"label": "", "start_age": 0}
		return config
	var animal := CardCalc.get_chinese_zodiac(_lunar_year)
	if not _ZODIAC_IDX.has(animal):
		for code in _GRID_CLOCKWISE:
			config[code] = {"label": "", "start_age": 0}
		return config
	var zodiac_idx: int = _ZODIAC_IDX[animal]
	var is_male := _get_is_male()
	var start_idx: int
	if is_male:
		start_idx = (zodiac_idx + _lunar_month - 1) % 12
	else:
		start_idx = (zodiac_idx - _lunar_month + 1 + 120) % 12
	for i in range(12):
		var pos_idx: int = (start_idx + i) % 12 if is_male else (start_idx - i + 120) % 12
		var code: String = _GRID_CLOCKWISE[pos_idx]
		var age_start: int = i * 10 + 1
		config[code] = {"label": "%d~%d歲" % [age_start, age_start + 9], "start_age": age_start}
	return config

func _calc_year_config() -> Dictionary:
	# code → {label, card, visible}
	var config: Dictionary = {}
	for code in _GRID_CLOCKWISE:
		config[code] = {"label": "", "card": code, "visible": false}
	if _decade_code == "" or _decade_start_age == 0:
		return config
	var start_idx: int = _GRID_CLOCKWISE.find(_decade_code)
	if start_idx < 0:
		return config
	var is_male := _get_is_male()
	for i in range(10):
		var pos_idx: int = (start_idx + i) % 12 if is_male else (start_idx - i + 120) % 12
		var cell_code: String = _GRID_CLOCKWISE[pos_idx]
		var card_code: String = _decade_code if i == 9 else cell_code
		config[cell_code] = {"label": str(_decade_start_age + i) + "歲", "card": card_code, "visible": true}
	return config

func _calc_day_config() -> Dictionary:
	var config: Dictionary = {}
	if _month_code == "":
		for code in _GRID_CLOCKWISE:
			config[code] = {"label": "", "card": code, "visible": true}
		return config
	var start_idx: int = _GRID_CLOCKWISE.find(_month_code)
	var is_male := _get_is_male()
	for i in range(12):
		var pos_idx: int = (start_idx + i) % 12 if is_male else (start_idx - i + 120) % 12
		var cell_code: String = _GRID_CLOCKWISE[pos_idx]
		var d1 := i + 1
		var d2 := d1 + 12
		var d3 := d1 + 24
		var lbl: String = "%d, %d, %d 號" % [d1, d2, d3] if d3 <= 30 else "%d, %d 號" % [d1, d2]
		config[cell_code] = {"label": lbl, "card": cell_code, "visible": true}
	return config

func _calc_month_config() -> Dictionary:
	var config: Dictionary = {}
	if _year_code == "":
		for code in _GRID_CLOCKWISE:
			config[code] = {"label": "", "card": code, "visible": true}
		return config
	var start_idx: int = _GRID_CLOCKWISE.find(_year_code)
	var is_male := _get_is_male()
	for i in range(12):
		var pos_idx: int = (start_idx + i) % 12 if is_male else (start_idx - i + 120) % 12
		var cell_code: String = _GRID_CLOCKWISE[pos_idx]
		config[cell_code] = {"label": str(i + 1) + "月", "card": cell_code, "visible": true}
	return config

func _build_fortune_config() -> Dictionary:
	# Unified: code → {label, card, visible, start_age}
	if _fortune_layer == 1:
		var decade := _calc_decade_config()
		var config: Dictionary = {}
		for code in decade:
			config[code] = {"label": decade[code]["label"], "card": code,
				"visible": true, "start_age": decade[code]["start_age"]}
		return config
	elif _fortune_layer == 2:
		var year := _calc_year_config()
		var config: Dictionary = {}
		for code in year:
			config[code] = {"label": year[code]["label"], "card": year[code]["card"],
				"visible": year[code]["visible"], "start_age": 0}
		return config
	elif _fortune_layer == 3:
		var month := _calc_month_config()
		var config: Dictionary = {}
		for code in month:
			config[code] = {"label": month[code]["label"], "card": code,
				"visible": month[code]["visible"], "start_age": 0}
		return config
	else:  # layer 4 or 5
		var day := _calc_day_config()
		var config: Dictionary = {}
		for code in day:
			config[code] = {"label": day[code]["label"], "card": code,
				"visible": day[code]["visible"], "start_age": 0}
		return config

func _panel_from_config(code: String, skin: String, style: StyleBoxFlat, cfg: Dictionary) -> PanelContainer:
	var on_tap := Callable()
	if _fortune_layer == 1 and cfg.get("start_age", 0) > 0:
		var c := code; var a: int = cfg["start_age"]
		on_tap = func(): _enter_year_fortune(c, a)
	elif _fortune_layer == 2 and cfg.get("visible", true):
		var c := code
		var dc: String = cfg.get("card", code)
		var lbl: String = cfg.get("label", "")
		on_tap = func(): _enter_month_fortune(c, dc, lbl)
	elif _fortune_layer == 3 and cfg.get("visible", true):
		var c := code
		var dc: String = cfg.get("card", code)
		var lbl: String = cfg.get("label", "")
		on_tap = func(): _enter_day_fortune(c, dc, lbl)
	elif _fortune_layer == 4 and cfg.get("visible", true):
		var c := code
		var dc: String = cfg.get("card", code)
		var lbl: String = cfg.get("label", "")
		on_tap = func(): _enter_day_selected(c, dc, lbl)
	var panel := _make_page2_panel(code, skin, style, cfg.get("label", ""), cfg.get("card", code), on_tap)
	var vbox := panel.get_child(0)
	var card_node := vbox.get_child(0) as TextureRect
	if not cfg.get("visible", true):
		card_node.modulate.a = 0.0
		(vbox.get_child(1) as Label).text = ""
	if _fortune_layer == 5:
		card_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel

func _enter_year_fortune(code: String, start_age: int) -> void:
	_fortune_layer = 2
	_decade_code = code
	_decade_start_age = start_age
	_year_code = ""
	_year_display_card = ""
	_year_label = ""
	_build_page2(_page_width)

func _enter_decade_fortune() -> void:
	_fortune_layer = 1
	_decade_code = ""; _decade_start_age = 0
	_year_code = ""; _year_display_card = ""; _year_label = ""
	_month_code = ""; _month_display_card = ""; _month_label = ""
	_day_code = ""; _day_display_card = ""; _day_label = ""
	await get_tree().create_timer(0.25).timeout
	_build_page2(_page_width)

func _enter_month_fortune(cell_code: String, display_card: String, label: String) -> void:
	_fortune_layer = 3
	_year_code = cell_code
	_year_display_card = display_card
	_year_label = label
	_month_code = ""; _month_display_card = ""; _month_label = ""
	_build_page2(_page_width)

func _return_to_year_fortune() -> void:
	_fortune_layer = 2
	_year_code = ""; _year_display_card = ""; _year_label = ""
	_month_code = ""; _month_display_card = ""; _month_label = ""
	_day_code = ""; _day_display_card = ""; _day_label = ""
	await get_tree().create_timer(0.25).timeout
	_build_page2(_page_width)

func _enter_day_fortune(cell_code: String, display_card: String, label: String) -> void:
	_fortune_layer = 4
	_month_code = cell_code
	_month_display_card = display_card
	_month_label = label
	_day_code = ""; _day_display_card = ""; _day_label = ""
	_build_page2(_page_width)

func _return_to_month_fortune() -> void:
	_fortune_layer = 3
	_month_code = ""; _month_display_card = ""; _month_label = ""
	_day_code = ""; _day_display_card = ""; _day_label = ""
	await get_tree().create_timer(0.25).timeout
	_build_page2(_page_width)

func _enter_day_selected(cell_code: String, display_card: String, label: String) -> void:
	_fortune_layer = 5
	_day_code = cell_code
	_day_display_card = display_card
	_day_label = label
	_build_page2(_page_width)

func _return_to_day_fortune() -> void:
	_fortune_layer = 4
	_day_code = ""; _day_display_card = ""; _day_label = ""
	await get_tree().create_timer(0.25).timeout
	_build_page2(_page_width)

func _build_page2(page_w: float) -> void:
	var fortune_config := _build_fortune_config()
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
		row1.add_child(_panel_from_config(code, page2_skin, panel_style, fortune_config.get(code, {})))

	# 中段：左欄(辰卯) | 中央資訊 | 右欄(酉戌)
	var mid := HBoxContainer.new()
	mid.add_theme_constant_override("separation", 6)
	rows.add_child(mid)

	var left_col := VBoxContainer.new()
	left_col.add_theme_constant_override("separation", 6)
	left_col.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	mid.add_child(left_col)
	left_col.add_child(_panel_from_config("BQ", page2_skin, panel_style, fortune_config.get("BQ", {})))
	left_col.add_child(_panel_from_config("RK", page2_skin, panel_style, fortune_config.get("RK", {})))

	mid.add_child(_build_page2_center_info())

	var right_col := VBoxContainer.new()
	right_col.add_theme_constant_override("separation", 6)
	right_col.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	mid.add_child(right_col)
	right_col.add_child(_panel_from_config("GK", page2_skin, panel_style, fortune_config.get("GK", {})))
	right_col.add_child(_panel_from_config("PQ", page2_skin, panel_style, fortune_config.get("PQ", {})))

	# 第四行：寅丑子亥
	var row4 := HBoxContainer.new()
	row4.add_theme_constant_override("separation", 6)
	rows.add_child(row4)
	for code in ["PB", "GQ", "BK", "RG"]:
		row4.add_child(_panel_from_config(code, page2_skin, panel_style, fortune_config.get(code, {})))

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
		card.modulate.a = 0.0
		var bottom_tap := Callable()
		if bl == "十年大運" and _fortune_layer >= 2 and _decade_code != "":
			card.texture = CardCalc.get_card_texture_for_skin(_decade_code, page2_skin)
			card.modulate.a = 1.0
			bottom_tap = func(): _enter_decade_fortune()
		elif bl == "流年" and _fortune_layer >= 3 and _year_code != "":
			card.texture = CardCalc.get_card_texture_for_skin(_year_display_card, page2_skin)
			card.modulate.a = 1.0
			bottom_tap = func(): _return_to_year_fortune()
		elif bl == "流月" and _fortune_layer >= 4 and _month_code != "":
			card.texture = CardCalc.get_card_texture_for_skin(_month_display_card, page2_skin)
			card.modulate.a = 1.0
			bottom_tap = func(): _return_to_month_fortune()
		elif bl == "流日" and _fortune_layer >= 5 and _day_code != "":
			card.texture = CardCalc.get_card_texture_for_skin(_day_display_card, page2_skin)
			card.modulate.a = 1.0
			bottom_tap = func(): _return_to_day_fortune()
		else:
			card.texture = CardCalc.get_card_texture_for_skin("BK", page2_skin)
		vbox.add_child(card)
		var label := Label.new()
		label.text = bl
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_font_size_override("font_size", 12)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(label)
		_attach_card_press_anim(card, bottom_tap)
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
