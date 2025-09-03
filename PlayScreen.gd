extends Control

# Game state variables
var game_width: int = 6
var game_height: int = 8
var game_active: bool = true

@onready var moves_display = $Dashboard/HBoxContainer/VBoxContainer/MovesDisplay
@onready var score_display = $Dashboard/HBoxContainer/VBoxContainer/ScoreDisplay
@onready var coins_display = $Dashboard/HBoxContainer/CoinsDisplay
@onready var game_lost_dialog = $GameLostDialog
@onready var dialog_score_label = $GameLostDialog/VBox/StatsContainer/ScoreContainer/ScoreLabel
@onready var dialog_coins_label = $GameLostDialog/VBox/StatsContainer/CoinsContainer/CoinsLabel
@onready var home_button = $ControlButtons/HomeButton
@onready var reset_button = $ControlButtons/ShuffleButton
@onready var reward_button = $ControlButtons/RewardButton
@onready var background = $Background
@onready var popup_manager = $PopupManager

func _ready():
	_setup_game()
	_connect_gamestate_signals()
	_apply_current_theme()
	
	_update_ui()

func _setup_game():
	# Initialize game state based on pseudocode specifications
	# Game board is 6x8 tiles as specified
	# Reset moves and score when entering PlayScreen
	GameState.reset_game()
	game_active = true
	_update_ui()

func _connect_gamestate_signals():
	# Connect to GameState signals for real-time UI updates
	GameState.moves_changed.connect(_on_moves_changed)
	GameState.score_changed.connect(_on_score_changed)
	GameState.coins_changed.connect(_on_coins_changed)
	GameState.game_lost.connect(_on_game_lost)
	GameState.theme_changed.connect(_on_theme_changed)

func _on_moves_changed(new_moves: int):
	_update_ui()
	moves_display.quantity = new_moves
	
func _on_score_changed(new_score: int):
	_update_ui()
	score_display.quantity = new_score

func _on_coins_changed(new_coins: int):
	_update_ui()
	coins_display.quantity = new_coins
	
func _on_game_lost():
	show_lost_dialog()

func _on_theme_changed(theme_data: Dictionary):
	_apply_theme(theme_data)

func _apply_current_theme():
	var theme_data = GameState.get_selected_theme_data()
	_apply_theme(theme_data)

func _apply_theme(theme_data: Dictionary):
	# Apply background color
	if background and theme_data.has("background_color"):
		background.color = theme_data["background_color"]
	
	# Apply theme resource
	if theme_data.has("theme_resource"):
		var theme_resource = load(theme_data["theme_resource"])
		if theme_resource:
			theme = theme_resource

func _update_ui():
	moves_display.update_quantity(GameState.moves_left)
	score_display.update_quantity(GameState.score)
	coins_display.update_quantity(GameState.coins)

func _disable_controls():
	if home_button:
		home_button.get_node("Button").disabled = true
	if reset_button:
		reset_button.disabled = true  
	if reward_button:
		reward_button.get_node("Button").disabled = true
	game_active = false

func _enable_controls():
	if home_button:
		home_button.get_node("Button").disabled = false
	if reset_button:
		reset_button.disabled = false
	if reward_button:
		reward_button.get_node("Button").disabled = false
	game_active = true

func show_lost_dialog():
	_disable_controls()
	# Update dialog with final stats
	dialog_score_label.text = "Final Score: " + str(GameState.score)
	var coins_earned = int(GameState.score / 50)
	dialog_coins_label.text = "Coins Earned: " + str(coins_earned)
	game_lost_dialog.popup_centered()
	game_lost_dialog.set_flag(Window.FLAG_POPUP, false)

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
	# Called from game lost dialog - navigate to home screen
	_enable_controls()
	game_lost_dialog.hide()
	get_tree().change_scene_to_file("res://TitleScreen.tscn")

# Placeholder method to simulate game over condition
func _input(event):
	# For testing - press 'G' to trigger game over dialog
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_G:
			show_lost_dialog()
