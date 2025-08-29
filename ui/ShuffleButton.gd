extends Control

signal shuffle_pressed

func _on_pressed():
	shuffle_pressed.emit()
