extends VBoxContainer

var Tag = preload("res://src/Tag.tscn")

var read_only = false

func setup(event, _read_only = false):
	read_only = _read_only

	# Clear tags
	for tag in $tags/v/v.get_children():
		tag.queue_free()

	$id/LineEdit.text = str(event.id)
	$pubkey/LineEdit.text = str(event.pubkey)
	$created_at/LineEdit.text = str(event.created_at)
	$kind/LineEdit.text = str(event.kind)

	for _tag in event.tags:
		var string = JSON.print(_tag)
		var new = Tag.instance()
		new.set_content(string, read_only)
		$tags/v/v.add_child(new)

	$content/LineEdit.text = str(event.content)
	$sig/LineEdit.text = str(event.sig)


	if read_only:
		$tags/v/add_tag.hide()
		$id/LineEdit.editable = false
		$pubkey/LineEdit.editable = false
		$created_at/LineEdit.editable = false
		$kind/LineEdit.editable = false
		$content/LineEdit.readonly = true
		$sig/LineEdit.editable = false
		$tools/Paste.hide()
	else:
		$tools/Copy.hide()




func get_event():
	var event: Dictionary = {
		"id": str($id/LineEdit.text),
		"pubkey": str($pubkey/LineEdit.text),
		"created_at": int($created_at/LineEdit.text),
		"kind": int($kind/LineEdit.text),
		"tags": [],
		"content": str($content/LineEdit.text),
		"sig": str($sig/LineEdit.text)
	}

	for _tag in $tags/v/v.get_children():
		event.tags.append((_tag.get_content()))

	return event

func _on_add_tag_button_up():
	var new = Tag.instance()
	$tags/v/v.add_child(new)


func _on_Copy_button_up():
	var event = get_event()
	var event_string = to_json(event)
	OS.set_clipboard(event_string)
	Global.add_log("Event copied..")


func _on_Paste_button_up():
	var content = OS.get_clipboard()
	var json = JSON.parse(content)
	if json.error == 0:
		var result = json.result
		if result.has("id") and result.has("pubkey") and result.has("created_at") and result.has("kind") and result.has("tags") and result.has("content") and result.has("sig"):
			setup(result)
			Global.add_log("Event pasted..")

