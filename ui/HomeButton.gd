extends Control

signal home_pressed

func _on_pressed():
	home_pressed.emit()
