extends Node

const VERSION = "0.1"

var logWindow = null

func add_log(text):
	if logWindow:
		logWindow.text += str(text) + "\n"
