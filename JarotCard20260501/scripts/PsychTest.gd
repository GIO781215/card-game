extends Control

const _OPTIONS: Array = ["非常符合", "符合", "不確定", "不太符合", "完全不符合"]

const _PAGES: Array = [
	{
		"title": "外在（對事/工作態度）1/4",
		"q_offset": 0,
		"questions": [
			"我認為邏輯比感情更能解決問題",
			"在團隊合作中，我會主動提出想法與方向",
			"我做事會先設定目標，再選擇有效率的方法",
			"面對爭議，我會先分析問題本質，而不是關注情緒",
			"我做決策時的優先考量是效率與結果",
			"我做決策會以邏輯與事實來判斷，而不是感覺",
			"面對任務，我會直接找人討論，而不是自己默默研究",
			"我習慣主動發起行動，而不是等待指示",
			"遇到問題時，我會先向外尋求資源與協助，速度比較快",
			"我喜歡與人溝通、交流，而不是獨自工作",
		]
	},
	{
		"title": "外在（對事/工作態度）2/4",
		"q_offset": 10,
		"questions": [
			"我做事要求明確、簡潔、直接，不拖泥帶水",
			"我會用溝通讓團隊達成共識",
			"我習慣主導進程，而不是追隨他人的安排",
			"我願意承擔繁瑣細節，只要能讓整體更順利",
			"我相信柔性的力量比強硬更能讓事情前進",
			"我會在工作中照顧到每個人的感受與狀態",
			"面對任務，我會直接給出方向與標準",
			"我在合作中會優先維持和諧氛圍",
			"如果團隊需要，我願意調整自己的角色",
		]
	},
	{
		"title": "內在（對人/人際關係）3/4",
		"q_offset": 0,
		"questions": [
			"我喜歡在人際互動中表達自己的想法與感受",
			"我在人際相處中通常是話比較多的那個",
			"我會主動與他人建立關係，而不等對方先靠近",
			"即使心裡有情緒，我會優先考慮如何有效解決問題",
			"我面對情緒時會先嘗試理解原因與邏輯",
			"我會將人際衝突切割成事件來處理，而不是個人問題",
			"我在處理關係問題時，常常能保持冷靜",
			"我的情緒比較容易通過與人溝通被緩解",
			"我常主動邀約、聯絡朋友或同事",
			"我傾向於站在旁觀角度分析人際互動",
		]
	},
	{
		"title": "內在（對人/人際關係）4/4",
		"q_offset": 10,
		"questions": [
			"我會細致感受別人的情緒並給予回應",
			"我常常把自己的需求放在後面，優先成全他人",
			"我會不自覺替別人考慮很多",
			"我在關係中追求互相理解和支持",
			"我願意配合對方的節奏，只要關係是和諧的",
			"我敢清楚表達立場，即使不被認同",
			"我願意為了維持關係，先退一步處理情緒",
			"面對衝突，我會直言不諱而不是隱忍沉默",
			"我很重視「做自己」，不喜歡迎合",
		]
	},
]

var _current_page: int = 0
var _answers: Array = []

var _touch_start_y: float = 0.0
var _scroll_start: int = 0
var _is_dragging: bool = false
var _mouse_pressed: bool = false
var _scroll_velocity: float = 0.0
var _prev_drag_y: float = 0.0
var _prev_drag_time: float = 0.0

func _ready() -> void:
	GameState.apply_background($BgImage)
	for page in _PAGES:
		var page_answers: Array = []
		for _q in page["questions"]:
			page_answers.append(-1)
		_answers.append(page_answers)
	_build_page(_current_page)
	%TitleLabel.add_theme_color_override("font_color", GameState.label_color())

func _build_page(page_idx: int) -> void:
	var page: Dictionary = _PAGES[page_idx]
	%TitleLabel.text = page["title"]
	%TitleLabel.add_theme_color_override("font_color", GameState.label_color())

	var vbox: VBoxContainer = %QuestionsVBox
	for child in vbox.get_children():
		child.queue_free()
	await get_tree().process_frame
	%ScrollContainer.scroll_vertical = 0

	var _tmp_btn := Button.new()
	vbox.add_child(_tmp_btn)
	var _base := _tmp_btn.get_theme_stylebox("normal") as StyleBoxFlat
	var base_alpha: float = _base.bg_color.a if _base else 0.5
	_tmp_btn.queue_free()

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(1, 1, 1, 0.08)
	normal_style.set_corner_radius_all(4)
	normal_style.set_content_margin_all(6)

	var selected_style := StyleBoxFlat.new()
	var sc := GameState.SELECTED_COLOR
	selected_style.bg_color = Color(sc.r, sc.g, sc.b, base_alpha)
	selected_style.set_corner_radius_all(4)
	selected_style.set_content_margin_all(6)

	for i in range(page["questions"].size()):
		var q_block := VBoxContainer.new()
		q_block.add_theme_constant_override("separation", 10)

		var q_label := Label.new()
		q_label.text = str(i + 1 + page["q_offset"]) + ".  " + page["questions"][i]
		q_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		q_label.add_theme_font_size_override("font_size", 19)
		q_label.add_theme_color_override("font_color", GameState.label_color())
		q_block.add_child(q_label)

		var opts_hbox := HBoxContainer.new()
		opts_hbox.add_theme_constant_override("separation", 6)
		var btn_group := ButtonGroup.new()

		for j in range(_OPTIONS.size()):
			var btn := Button.new()
			btn.text = _OPTIONS[j]
			btn.toggle_mode = true
			btn.button_group = btn_group
			btn.add_theme_font_size_override("font_size", 14)
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.custom_minimum_size = Vector2(0, 48)
			btn.add_theme_stylebox_override("normal",   normal_style)
			btn.add_theme_stylebox_override("hover",    normal_style)
			btn.add_theme_stylebox_override("pressed",  selected_style)
			btn.add_theme_stylebox_override("focus",    normal_style)
			if _answers[page_idx][i] == j:
				btn.button_pressed = true
			var pi := page_idx
			var qi := i
			var oi := j
			btn.toggled.connect(func(pressed: bool): if pressed: _answers[pi][qi] = oi)
			opts_hbox.add_child(btn)

		q_block.add_child(opts_hbox)
		var bottom_pad := Control.new()
		bottom_pad.custom_minimum_size = Vector2(0, 12)
		q_block.add_child(bottom_pad)
		vbox.add_child(q_block)

	# 頁面導覽按鈕（置中，隨內容滾動）
	var nav_row := HBoxContainer.new()
	nav_row.add_theme_constant_override("separation", 16)
	nav_row.custom_minimum_size = Vector2(0, 68)
	nav_row.alignment = BoxContainer.ALIGNMENT_CENTER

	if page_idx > 0:
		var prev_btn := Button.new()
		prev_btn.text = "上一頁"
		prev_btn.custom_minimum_size = Vector2(170, 52)
		prev_btn.add_theme_font_size_override("font_size", 22)
		prev_btn.pressed.connect(func():
			if not _is_dragging:
				_current_page -= 1
				_build_page(_current_page))
		nav_row.add_child(prev_btn)

	var next_btn := Button.new()
	next_btn.add_theme_font_size_override("font_size", 22)
	next_btn.custom_minimum_size = Vector2(170, 52)
	if page_idx == _PAGES.size() - 1:
		next_btn.text = "查看結果"
		next_btn.pressed.connect(func():
			if not _is_dragging: pass)  # TODO: 顯示結果
	else:
		next_btn.text = "下一頁"
		next_btn.pressed.connect(func():
			if not _is_dragging:
				_current_page += 1
				_build_page(_current_page))
	nav_row.add_child(next_btn)

	vbox.add_child(nav_row)

func _process(delta: float) -> void:
	var sc: ScrollContainer = %ScrollContainer
	if absf(_scroll_velocity) < 30.0:
		_scroll_velocity = 0.0
		return
	sc.scroll_vertical += int(_scroll_velocity * delta)
	_scroll_velocity *= pow(0.1, delta)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _input(event: InputEvent) -> void:
	var sc: ScrollContainer = %ScrollContainer
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start_y = event.position.y
			_scroll_start = sc.scroll_vertical
			_is_dragging = false
			_scroll_velocity = 0.0
			_prev_drag_y = event.position.y
			_prev_drag_time = Time.get_ticks_msec() / 1000.0
		else:
			if _is_dragging:
				get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if absf(event.position.y - _touch_start_y) > 8.0:
			_is_dragging = true
		if _is_dragging:
			sc.scroll_vertical = _scroll_start + int(_touch_start_y - event.position.y)
			var now := Time.get_ticks_msec() / 1000.0
			var dt := now - _prev_drag_time
			if dt > 0.005:
				_scroll_velocity = lerpf(_scroll_velocity, (_prev_drag_y - event.position.y) / dt, 0.5)
				_prev_drag_y = event.position.y
				_prev_drag_time = now
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_mouse_pressed = true
				_touch_start_y = mb.position.y
				_scroll_start = sc.scroll_vertical
				_is_dragging = false
				_scroll_velocity = 0.0
				_prev_drag_y = mb.position.y
				_prev_drag_time = Time.get_ticks_msec() / 1000.0
			else:
				_mouse_pressed = false
				if _is_dragging:
					get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _mouse_pressed:
		var mm := event as InputEventMouseMotion
		if absf(mm.position.y - _touch_start_y) > 8.0:
			_is_dragging = true
		if _is_dragging:
			sc.scroll_vertical = _scroll_start + int(_touch_start_y - mm.position.y)
			var now := Time.get_ticks_msec() / 1000.0
			var dt := now - _prev_drag_time
			if dt > 0.005:
				_scroll_velocity = lerpf(_scroll_velocity, (_prev_drag_y - mm.position.y) / dt, 0.5)
				_prev_drag_y = mm.position.y
				_prev_drag_time = now
			get_viewport().set_input_as_handled()
