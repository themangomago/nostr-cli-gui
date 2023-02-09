extends VBoxContainer

var FilterOption = preload("res://src/FilterOption.tscn")
var Event = preload("res://src/Event.tscn")

const FilterOptions = [
	{"option": "ids", "value": "[]", "tooltip": "a list of event ids or prefixes"},
	{"option": "authors", "value": "[]", "tooltip": "a list of pubkeys or prefixes, the pubkey of an event must be one of these"},
	{"option": "kinds", "value": "[]", "tooltip": "a list of a kind numbers"},
	{"option": "#e", "value": "[]", "tooltip": "a list of event ids that are referenced in an 'e' tag"},
	{"option": "#p", "value": "[]", "tooltip": "a list of pubkeys that are referenced in a 'p' tag"},
	{"option": "since", "value": 0, "tooltip": "an integer unix timestamp, events must be newer than this to pass"},
	{"option": "until", "value": 0, "tooltip": "an integer unix timestamp, events must be older than this to pass"},
	{"option": "limit", "value": 0, "tooltip": "maximum number of events to be returned in the initial query"}
]



func _on_add_tag_button_up():
	var filter = FilterOption.instance()
	filter.setup(FilterOptions)
	$v.add_child(filter)


func get_filter():
	var seenFilters = []
	var filter = {}

	for option in $v.get_children():
		var data = option.get_filter()
		var optionName = FilterOptions[data.option].option

		if data.option in seenFilters:
			Global.add_log("Error: Duplicated entry found '" + optionName + "'.")
			return null

		seenFilters.append(data.option)

		filter[optionName] = data.value

	return filter

func hide_results():
	for child in $results.get_children():
		child.queue_free()

func show_results(events: Array):
	for event in events:
		$results.add_child(HSeparator.new())
		var node = Event.instance()
		node.setup(event, true)
		$results.add_child(node)

