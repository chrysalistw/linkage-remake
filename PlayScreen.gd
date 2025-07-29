extends Control

# Game state variables
var game_width: int = 6
var game_height: int = 8
var game_active: bool = true

@onready var moves_label = $Dashboard/MovesLabel
@onready var score_label = $Dashboard/ScoreLabel
@onready var game_lost_dialog = $GameLostDialog
@onready var home_button = $ControlButtons/HomeButton
@onready var reset_button = $ControlButtons/ResetButton
@onready var reward_button = $ControlButtons/RewardButton

func _ready():
	_setup_game()
	_connect_gamestate_signals()
	_update_ui()

func _setup_game():
	# Initialize game state based on pseudocode specifications
	# Game board is 6x8 tiles as specified
	game_active = true
	_update_ui()

func _connect_gamestate_signals():
	# Connect to GameState signals for real-time UI updates
	GameState.moves_changed.connect(_on_moves_changed)
	GameState.score_changed.connect(_on_score_changed)
	GameState.game_lost.connect(_on_game_lost)

func _on_moves_changed(new_moves: int):
	moves_label.text = "MOVES LEFT: " + str(new_moves)
	
func _on_score_changed(new_score: int):
	score_label.text = "SCORE: " + str(new_score)
	
func _on_game_lost():
	show_lost_dialog()

func _update_ui():
	moves_label.text = "MOVES LEFT: " + str(GameState.moves_left)
	score_label.text = "SCORE: " + str(GameState.score)

func _disable_controls():
	if home_button:
		home_button.disabled = true
	if reset_button:
		reset_button.disabled = true  
	if reward_button:
		reward_button.disabled = true
	game_active = false

func _enable_controls():
	if home_button:
		home_button.disabled = false
	if reset_button:
		reset_button.disabled = false
	if reward_button:
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
	# Reset the game using GameState
	GameState.restart_game()

func _on_reward_button_pressed():
	if not game_active:
		return
	# Trigger reward functionality through GameState
	GameState._on_reward_earned()
	GameState._on_reward_requested()
	print("Reward ad watched - 10 moves lost, tiles replaced")

func _on_restart_button_pressed():
	# Called from game lost dialog
	_enable_controls()
	game_lost_dialog.hide()
	GameState.restart_game()

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
