extends Control

# Game state variables
var game_width: int = 6
var game_height: int = 8
var game_active: bool = true
var pending_reward: bool = false

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
@onready var debug_coin_button = $DebugCoinButton
@onready var reward_confirm_dialog = $RewardConfirmDialog
@onready var home_confirm_dialog = $HomeConfirmDialog
@onready var reward_message_label = $RewardConfirmDialog/VBox/MessageLabel
@onready var reward_watch_button = $RewardConfirmDialog/VBox/ButtonContainer/WatchButton

func _ready():
	_setup_game()
	_connect_gamestate_signals()
	_connect_admob_signals()
	_apply_current_theme()
	
	_update_ui()
	
	# Pre-load rewarded ad
	AdMobManager.load_rewarded()

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

func _connect_admob_signals():
	# Connect to AdMobManager signals
	AdMobManager.rewarded_ad_earned_reward.connect(_on_rewarded_ad_earned)
	AdMobManager.rewarded_ad_failed_to_load.connect(_on_rewarded_ad_failed)
	AdMobManager.rewarded_ad_dismissed.connect(_on_rewarded_ad_dismissed)

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
		reset_button.get_node("Button").disabled = true  
	if reward_button:
		reward_button.get_node("Button").disabled = true
	game_active = false

func _enable_controls():
	if home_button:
		home_button.get_node("Button").disabled = false
	if reset_button:
		reset_button.get_node("Button").disabled = false
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
	# Show confirmation dialog instead of directly navigating
	home_confirm_dialog.popup_centered()
	home_confirm_dialog.set_flag(Window.FLAG_POPUP, false)

func _on_reset_button_pressed():
	if not game_active:
		return
	# Reset the game using GameState
	GameState.restart_game()

func _on_reward_button_pressed():
	if not game_active:
		return
	
	# Show confirmation dialog and update coin status
	_update_reward_dialog_state()
	reward_confirm_dialog.popup_centered()
	reward_confirm_dialog.set_flag(Window.FLAG_POPUP, false)

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

func _on_debug_coin_button_pressed():
	# Debug function to give 100 coins
	GameState.add_coins(100)
	print("Debug: Added 100 coins - Total coins: ", GameState.coins)

func _on_rewarded_ad_earned(reward_item):
	# Called when user successfully watches rewarded ad
	print("Reward earned! Will apply when ad closes...")
	pending_reward = true

func _on_rewarded_ad_failed(error):
	# Called when rewarded ad fails to load
	print("Rewarded ad failed to load: ", error)
	popup_manager.show_popup("Ad not available. Try again later.", 2.0)
	pending_reward = false

func _on_rewarded_ad_dismissed():
	# Called when rewarded ad is completely closed
	print("Rewarded ad dismissed")
	if pending_reward:
		print("Applying reward now - starting tile replacement animation...")
		# Apply the reward logic without consuming coins (reward is from ad)
		await get_tree().process_frame
		get_tree().call_group("gameboard", "apply_tile_replacement_reward")
		#popup_manager.show_popup("Reward applied! Bad tiles replaced!", 2.0)
		pending_reward = false

# Confirmation dialog handlers
func _on_reward_cancel_pressed():
	# Close the reward confirmation dialog
	reward_confirm_dialog.hide()

func _update_reward_dialog_state():
	# Update message with coin status
	var has_enough_coins = GameState.coins >= 10
	var base_message = "Spend 10 coins and watch a short ad to replace bad tiles with better ones?"
	var coin_status = "\n\nYour coins: " + str(GameState.coins) + " / 10 required"
	
	reward_message_label.text = base_message + coin_status
	
	# Enable/disable the watch button based on coin availability
	reward_watch_button.disabled = not has_enough_coins
	
	# Change button text and label color based on coin status
	if has_enough_coins:
		reward_watch_button.text = "Watch Ad"
		reward_message_label.modulate = Color.WHITE
	else:
		reward_watch_button.text = "Not Enough Coins"
		reward_message_label.modulate = Color.WHITE
		# Color just the coin status part red by using a different approach
		reward_message_label.text = base_message + "\n\n[color=red]Your coins: " + str(GameState.coins) + " / 10 required[/color]"
		#reward_message_label.bbcode_enabled = true

func _on_reward_confirm_pressed():
	# Only proceed if player has enough coins (extra safety check)
	if GameState.coins < 10:
		return
	
	# Close dialog and proceed with reward ad
	reward_confirm_dialog.hide()
	
	# Deduct 10 coins for the reward
	GameState.coins -= 10
	
	# Check if rewarded ad is available
	if AdMobManager.is_rewarded_ad_ready():
		print("Showing rewarded ad...")
		AdMobManager.show_rewarded()
	else:
		print("Rewarded ad not ready, trying to load...")
		AdMobManager.load_rewarded()
		# Show feedback to user that ad is loading
		#popup_manager.show_popup("Loading reward ad...", 2.0)

func _on_home_cancel_pressed():
	# Close the home confirmation dialog
	home_confirm_dialog.hide()

func _on_home_confirm_pressed():
	# Close dialog and navigate to home screen
	home_confirm_dialog.hide()
	get_tree().change_scene_to_file("res://TitleScreen.tscn")

# Placeholder method to simulate game over condition
func _input(event):
	# For testing - press 'G' to trigger game over dialog
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_G:
			show_lost_dialog()
