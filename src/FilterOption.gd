extends HBoxContainer

var Filter: Array

func setup(filter):
	Filter = filter
	for item in filter:
		$OptionButton.add_item(item.option)

	switch(0)

func switch(index):
	#{"option": "limit", "value": 0, "tooltip": "maximum number of events to be returned in the initial query"}
	$LineEdit.text = str(Filter[index].value)
	$LineEdit.hint_tooltip = Filter[index].tooltip

func get_filter():
	return {"option": $OptionButton.selected, "value": $LineEdit.text}


func _on_Button_button_up():
	queue_free()


func _on_OptionButton_item_selected(index):
	switch(index)
