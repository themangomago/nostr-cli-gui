extends Control

const executables = ["./nostrcli", "nostrcli.exe"]
var os_id = 0

var Event = preload("res://src/Event.tscn")
var Filter = preload("res://src/Filter.tscn")

const event_template = {
		"id": "0",
		"pubkey": "0",
		"created_at": 0,
		"kind": "1",
		"tags": [],
		"content": "",
		"sig": ""
	}


var templates: Array = [
	{
		"file": "empty",
		"event": event_template.duplicate(true)
	}
]

var current_event: Dictionary = event_template.duplicate(true)
var result_event: Array = []

func _ready():
	if OS.get_name() == "Windows":
		os_id = 1

	Global.logWindow = $v/h/v/Log

	setup_toolbar()

	var tree = $v/h/files/Tree
	var root = tree.create_item()

	tree.set_hide_root(true)
	var child1 = tree.create_item(root)
	child1.set_text(0, "TestCollection")
	var subchild1 = tree.create_item(child1)
	subchild1.set_text(0, "Republish")
	var subchild2 = tree.create_item(child1)
	subchild2.set_text(0, "Contact")

	# Parse Templates
	parse_templates("templates")

	# Add Types
	$v/h/v/v/toolbuttons/TypeOption.add_item("event", 0)
	$v/h/v/v/toolbuttons/TypeOption.add_item("request", 1)

	# Add Options
	for template in templates:
		$v/h/v/v/toolbuttons/TemplateOption.add_item(template.file)

	# Set Empty Template
	switch_view(0)
	set_template(0)
	Global.add_log("Templates loaded")

func switch_view(index):
	# Remove and store old events
	remove_events(index)

	if (index == 1):
		# Request View
		$v/h/v/v/toolbuttons/TemplateOption.disabled = true
		var filter = Filter.instance()
		$v/h/v/v/scroll/v.add_child(filter)

	else:
		# Event View
		$v/h/v/v/toolbuttons/TemplateOption.disabled = false
		var event = Event.instance()
		$v/h/v/v/scroll/v.add_child(event)
		event.setup(current_event)

func setup_toolbar():
	var popup = $v/toolbar/File.get_popup()
	popup.add_item("Quit")
	popup.connect("id_pressed", self, "_file_item_pressed")

	popup = $v/toolbar/Help.get_popup()
	popup.add_item("Version")
	popup.add_item("Help")
	popup.connect("id_pressed", self, "_help_item_pressed")


func _file_item_pressed(id):
	if id == 0:
		get_tree().quit()

func _help_item_pressed(id):
	if id == 0:
		Global.add_log("Version: " + str(Global.VERSION))
	elif id == 1:
		OS.shell_open("https://github.com/themangomago/nostr-cli-gui")


func remove_events(index):
	for event in $v/h/v/v/scroll/v.get_children():
		event.queue_free()



func set_template(id):
	var event = $v/h/v/v/scroll/v.get_child(0)

	if event:
		event.setup(templates[id].event)

#	# Clear tags
#	for tag in $v/scroll/v/tags/v/Event.get_children():
#		tag.queue_free()
#
#	$v/scroll/v/id/LineEdit.text = str(templates[id].event.id)
#	$v/scroll/v/pubkey/LineEdit.text = str(templates[id].event.pubkey)
#	$v/scroll/v/created_at/LineEdit.text = str(templates[id].event.created_at)
#	$v/scroll/v/kind/LineEdit.text = str(templates[id].event.kind)
#
#	for _tag in templates[id].event.tags:
#		var string = JSON.print(_tag)
#		var new = Tag.instance()
#		new.set_content(string)
#		$v/scroll/v/tags/v/v.add_child(new)
#
#	$v/scroll/v/content/LineEdit.text = str(templates[id].event.content)
#	$v/scroll/v/sig/LineEdit.text = str(templates[id].event.sig)


func parse_templates(path):
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()

	while true:
		var file_name = dir.get_next()
		if file_name == "":
			break
		elif file_name.ends_with(".json"):
			var file = File.new()
			file.open(path+ "/" + file_name, File.READ)
			var content = file.get_as_text()
			var json: JSONParseResult  = JSON.parse(content)
			file.close()

			if json.error == 0:
				if is_valid_event(json.result):
					templates.append({"file": file_name, "event": json.result})

	dir.list_dir_end()



func save(file, event):
	var fh = File.new()
	fh.open(file, File.WRITE)
	fh.store_line(to_json(event))
	fh.close()
	Global.add_log("Saved as: " + file)

func is_valid_event(event):
	if event.has("id") and event.has("pubkey") and event.has("created_at") and event.has("kind") and event.has("tags") and event.has("content") and event.has("sig"):
		return true
	return false


func _on_SendButton_button_up():
	var child = $v/h/v/v/scroll/v.get_child(0)
	if child:
		if $v/h/v/v/toolbuttons/TypeOption.selected == 0:
			var event = child.get_event()
			save("event.json", event)


			var params = [
				"-f=\"event.json\"",
				"-t=\"event\"",
				"-r=\"" + $v/h/v/v/relay/LineEdit.text + "\"",
				"-k=\"" + $v/h/v/v/priv/LineEdit.text + "\""
			]
			var output = nostrcli(params)

			if output[0].find("Event published.") != -1:
				Global.add_log("Published.")
			else:
				Global.add_log("Error publishing check logs.")
				print(output)

		else:
			var filter = child.get_filter()
			if filter == null:
				return

			child.hide_results()
			save("filter.json", filter)

			var params = [
				"-f=\"filter.json\"",
				"-t=\"req\"",
				"-r=\"" + $v/h/v/v/relay/LineEdit.text + "\"",
				"-o=\"results.json\""
			]
			var output = nostrcli(params)
			if output[0].find("-[NostrCli]") != -1:
				var events = getEventsFromResult(output)
				if events:
					child.show_results(events)
			else:
				Global.add_log("Error getting results.")
				print(output)





func getEventsFromResult(output):
	if output.size() > 0:
		if output[0].find("result.json"):
			var fh = File.new()
			fh.open("results.json", File.READ)
			var text = fh.get_as_text()
			var json = JSON.parse(text)
			if json.error == OK:
				Global.add_log("Events received.")
				return json.result
			else:
				Global.add_log("Error paring results.json")

		else:
			Global.add_log("nostrcli error the results.json not generated.")
	return null


func nostrcli(params: Array) -> Array:
	var output = []

	var string = ""
	for param in params:
		string += param + " "

	Global.add_log("Calling: nostrcli " + string)
	var result = OS.execute(executables[os_id], params, true, output, true )
	print("Output: ")
	print(output)
	print(result)
	return output



func _on_SaveButton_button_up():
	var child = $v/h/v/v/scroll/v.get_child(0)
	if child:
		if $v/h/v/v/toolbuttons/TypeOption.selected == 0:
			var event = child.get_event()
			save("event.json", event)
		else:
			var filter = child.get_filter()
			if filter != null:
				save("filter.json", filter)

func _on_TypeOption_item_selected(index):
	switch_view(index)

func _on_TemplateOption_item_selected(index):
	set_template(index)
