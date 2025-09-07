extends Node

# Global game state singleton for managing game data across scenes
# Based on game.js pseudocode

signal moves_changed(new_moves: int)
signal score_changed(new_score: int)
signal game_lost()
signal reward_earned()
signal tiles_about_to_score(tile_count: int)
signal moves_about_to_be_awarded(move_count: int)


# Game state variables
var moves_left: int = 100 :
	set(value):
		moves_left = value
		emit_signal("moves_changed", moves_left)
		if moves_left <= 0:
			lost = true
			convert_score_to_coins()
			emit_signal("game_lost")
			

var score: int = 0 :
	set(value):
		score = value
		emit_signal("score_changed", score)

signal coins_changed(new_coins: int)
signal high_score_changed(new_high_score: int)

var coins: int = 0 :
	set(value):
		coins = value
		emit_signal("coins_changed", coins)
		if not _loading_data:
			save_game_data()

var high_score: int = 0 :
	set(value):
		high_score = value
		emit_signal("high_score_changed", high_score)
		if not _loading_data:
			save_game_data()

var lost: bool = false
var is_reward_earned: bool = false :
	set(value):
		is_reward_earned = value
		if is_reward_earned:
			emit_signal("reward_earned")

# Board configuration
var board_width: int = 6
var board_height: int = 8
var tile_size: int = 64

# Sprite settings
var current_sprite: String = "green"
var removing_sprite: String = "green_fade"

# Theme environment management - now uses ThemeManager
var available_themes: Array[Dictionary] = []
var selected_theme_index: int = 0  # Default to Green Default

signal theme_changed(theme_data: Dictionary)

# Save file path
const SAVE_FILE_PATH = "user://game_data.cfg"
var _loading_data: bool = false

# Audio
var sounds: Dictionary = {}

func _ready():
	# Initialize theme manager
	var theme_manager = ThemeManager.new()
	theme_manager.load_themes()
	available_themes = theme_manager.themes
	print("GameState: Loaded ", available_themes.size(), " themes")
	for i in range(available_themes.size()):
		print("Theme ", i, ": ", available_themes[i].get("name", "Unknown"))
	# Load persistent data first
	load_game_data()
	# Apply the loaded theme
	_apply_loaded_theme()
	# Initialize default values
	reset_game()

func reset_game():
	moves_left = 100
	score = 0
	lost = false
	is_reward_earned = false

func add_score(points: int):
	score += points

func add_coins(amount: int):
	coins += amount

func convert_score_to_coins():
	# Update high score if current score is higher
	if score > high_score:
		high_score = score
	
	# Convert score to coins
	var coins_earned = int(score / 50)
	if coins_earned > 0:
		add_coins(coins_earned)

func use_move():
	moves_left -= 1

func set_high_score():
	# Android integration - report high score
	if OS.get_name() == "Android":
		# Call Android interface if available
		pass

# Reward system - randomizes tiles (called from Android)
func apply_reward():
	if is_reward_earned:
		# This will be handled by the GameBoard
		moves_left -= 10  # Cost of using reward
		is_reward_earned = false
		return true
	return false

func play_sound(sound_name: String):
	if sounds.has(sound_name):
		var audio_player = sounds[sound_name]
		if audio_player and audio_player is AudioStreamPlayer:
			audio_player.play()

func load_sound(sound_name: String, audio_stream: AudioStream):
	var audio_player = AudioStreamPlayer.new()
	audio_player.stream = audio_stream
	add_child(audio_player)
	sounds[sound_name] = audio_player

func restart_game():
	await get_tree().process_frame  # Wait a frame
	reset_game()
	# Signal to restart the current game
	get_tree().call_group("gameboard", "initialize_board")

func _on_reward_earned():
	is_reward_earned = true

func _on_reward_requested():
	if is_reward_earned:
		await get_tree().process_frame
		# Signal to apply deus ex machina
		get_tree().call_group("gameboard", "apply_deus_ex_machina")
		apply_reward()

func use_coins_for_reward():
	# Check if player has enough coins
	if coins < 10:
		print("Not enough coins for reward")
		return false
	
	# Consume 10 coins
	coins -= 10
	
	# Trigger tile replacement
	await get_tree().process_frame
	get_tree().call_group("gameboard", "apply_tile_replacement_reward")
	
	return true

# Theme environment management functions
func get_selected_theme_data() -> Dictionary:
	if selected_theme_index >= 0 and selected_theme_index < available_themes.size():
		return available_themes[selected_theme_index]
	return available_themes[0]  # Fallback to Blue Modern

func get_selected_tileset_resource() -> String:
	return get_selected_theme_data()["tileset_path"]

func get_selected_theme_resource() -> String:
	return get_selected_theme_data()["theme_path"]

func get_selected_background_color() -> Color:
	var bg_color = get_selected_theme_data()["background_color"]
	if bg_color is String:
		return Color(bg_color)
	return bg_color

func set_selected_theme(index: int):
	if index >= 0 and index < available_themes.size():
		selected_theme_index = index
		var theme_data = available_themes[index]
		# Save the theme preference immediately
		save_game_data()
		emit_signal("theme_changed", theme_data)

func _apply_loaded_theme():
	# Apply the loaded theme on startup
	if selected_theme_index >= 0 and selected_theme_index < available_themes.size():
		var theme_data = available_themes[selected_theme_index]
		emit_signal("theme_changed", theme_data)
		print("GameState: Applied loaded theme: ", theme_data.get("name", "Unknown"))

func get_theme_name(index: int) -> String:
	if index >= 0 and index < available_themes.size():
		return available_themes[index]["name"]
	return "Unknown"

func get_theme_count() -> int:
	return available_themes.size()

# Save/Load system
func save_game_data():
	var config = ConfigFile.new()
	
	# Save persistent data
	config.set_value("game", "coins", coins)
	config.set_value("game", "high_score", high_score)
	config.set_value("game", "selected_theme_index", selected_theme_index)
	
	# Save to file
	var error = config.save(SAVE_FILE_PATH)
	if error != OK:
		print("Failed to save game data: ", error)

func load_game_data():
	var config = ConfigFile.new()
	
	# Load config file
	var error = config.load(SAVE_FILE_PATH)
	if error != OK:
		print("No save file found or failed to load: ", error)
		return
	
	# Set loading flag to prevent saving during load
	_loading_data = true
	
	# Load persistent data (use current values as defaults)
	coins = config.get_value("game", "coins", 0)
	high_score = config.get_value("game", "high_score", 0)  
	selected_theme_index = config.get_value("game", "selected_theme_index", 1)
	
	# Clear loading flag
	_loading_data = false
	
	print("Loaded data - Coins: ", coins, " High Score: ", high_score)
