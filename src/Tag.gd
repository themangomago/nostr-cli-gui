extends HBoxContainer


func get_content():
	return JSON.parse($LineEdit.text).result

func set_content(text, read_only = false):
	$LineEdit.text = text

	if read_only:
		$Button.hide()
		$LineEdit.editable = false

func _on_Button_button_up():
	queue_free()


