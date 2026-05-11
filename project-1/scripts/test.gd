extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	print("按鈕被按了")


func _on_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		print("狀態1")
	else:
		print("狀態2")
