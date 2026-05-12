extends Control

var _birthday_type: String = "solar"
var _touch_start_y: float = 0.0
var _scroll_start: int = 0

func _ready() -> void:
	GameState.apply_background($BgImage)
	var person: Dictionary = GameState.person_list[GameState.current_person_index]
	if not person.has("gender"):
		person["gender"] = "male"
		GameState.save_data()
	%NameLabel.text = person["name"]
	GameState.apply_label_color(%NameLabel)
	_update_birthday_buttons()
	_update_gender_button()

func _update_birthday_buttons() -> void:
	var person: Dictionary = GameState.person_list[GameState.current_person_index]
	var solar: String = person.get("birthday_solar", "")
	var lunar: String = person.get("birthday_lunar", "")
	%SolarBtn.text = solar if solar != "" else "請輸入"
	%LunarBtn.text = lunar if lunar != "" else "請輸入"

func _update_gender_button() -> void:
	var person: Dictionary = GameState.person_list[GameState.current_person_index]
	var gender: String = person.get("gender", "male")
	%GenderToggleBtn.text = "♂ 男" if gender == "male" else "♀ 女"

func _on_gender_toggle_pressed() -> void:
	var person: Dictionary = GameState.person_list[GameState.current_person_index]
	var gender: String = person.get("gender", "male")
	person["gender"] = "female" if gender == "male" else "male"
	GameState.save_data()
	_update_gender_button()

func _on_solar_btn_pressed() -> void:
	_birthday_type = "solar"
	var person: Dictionary = GameState.person_list[GameState.current_person_index]
	(%BirthdayTypeLabel as Label).text = "國曆生日"
	(%BirthdayInput as LineEdit).text = person.get("birthday_solar", "")
	%BirthdayOverlay.visible = true

func _on_lunar_btn_pressed() -> void:
	_birthday_type = "lunar"
	var person: Dictionary = GameState.person_list[GameState.current_person_index]
	(%BirthdayTypeLabel as Label).text = "農曆生日"
	(%BirthdayInput as LineEdit).text = person.get("birthday_lunar", "")
	%BirthdayOverlay.visible = true

func _on_confirm_birthday_pressed() -> void:
	var date: String = (%BirthdayInput as LineEdit).text.strip_edges()
	var person: Dictionary = GameState.person_list[GameState.current_person_index]
	if _birthday_type == "solar":
		person["birthday_solar"] = date
	else:
		person["birthday_lunar"] = date
	GameState.save_data()
	%BirthdayOverlay.visible = false
	_update_birthday_buttons()

func _on_cancel_birthday_pressed() -> void:
	%BirthdayOverlay.visible = false

func _unhandled_input(event: InputEvent) -> void:
	var sc: ScrollContainer = $MainVBox/ScrollContainer
	if event is InputEventScreenTouch and event.pressed:
		_touch_start_y = event.position.y
		_scroll_start = sc.scroll_vertical
	elif event is InputEventScreenDrag:
		sc.scroll_vertical = _scroll_start + int(_touch_start_y - event.position.y)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/CardLookup.tscn")
