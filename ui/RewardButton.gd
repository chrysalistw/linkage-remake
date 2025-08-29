extends Control

signal reward_pressed

func _on_pressed():
	reward_pressed.emit()
