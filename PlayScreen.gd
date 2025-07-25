extends Control

# Game state variables
var moves_left: int = 50
var score: int = 0
var game_width: int = 6
var game_height: int = 8
var game_active: bool = true

@onready var moves_label = $Dashboard/MovesLabel
@onready var score_label = $Dashboard/ScoreLabel
@onready var game_lost_dialog = $GameLostDialog
@onready var home_button = $Dashboard/ControlButtons/HomeButton
@onready var reset_button = $Dashboard/ControlButtons/ResetButton
@onready var reward_button = $Dashboard/ControlButtons/RewardButton

func _ready():
	_setup_game()
	_update_ui()

func _setup_game():
	# Initialize game state based on pseudocode specifications
	# Game board is 6x8 tiles as specified
	game_active = true
	_update_ui()

func _update_ui():
	moves_label.text = "MOVES LEFT: " + str(moves_left)
	score_label.text = "SCORE: " + str(score)

func _disable_controls():
	home_button.disabled = true
	reset_button.disabled = true  
	reward_button.disabled = true
	game_active = false

func _enable_controls():
	home_button.disabled = false
	reset_button.disabled = false
	reward_button.disabled = false
	game_active = true

func show_lost_dialog():
	_disable_controls()
	game_lost_dialog.popup_centered()

func _on_home_button_pressed():
	if not game_active:
		return
	# Navigate back to title screen
	get_tree().change_scene_to_file("res://TitleScreen.tscn")

func _on_reset_button_pressed():
	if not game_active:
		return
	# Reset the game
	moves_left = 50
	score = 0
	_setup_game()

func _on_reward_button_pressed():
	if not game_active:
		return
	# Placeholder for reward ad functionality
	# According to pseudocode: lose 10 moves, replace half tiles randomly
	moves_left -= 10
	if moves_left < 0:
		moves_left = 0
	_update_ui()
	print("Reward ad watched - 10 moves lost, tiles replaced")

func _on_restart_button_pressed():
	# Called from game lost dialog
	_enable_controls()
	game_lost_dialog.hide()
	moves_left = 50
	score = 0
	_setup_game()

func _on_fine_button_pressed():
	# Called from game lost dialog
	_enable_controls()
	game_lost_dialog.hide()

# Placeholder method to simulate game over condition
func _input(event):
	# For testing - press 'G' to trigger game over dialog
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_G:
			show_lost_dialog()
