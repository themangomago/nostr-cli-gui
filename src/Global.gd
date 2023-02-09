extends Node

var logWindow = null

func add_log(text):
	if logWindow:
		logWindow.text += str(text) + "\n"
