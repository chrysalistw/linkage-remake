extends Node

# Global game state singleton for managing game data across scenes
# Based on game.js pseudocode

signal moves_changed(new_moves: int)
signal score_changed(new_score: int)
signal game_lost()
signal reward_earned()

# Game state variables
var moves_left: int = 100 :
	set(value):
		moves_left = value
		emit_signal("moves_changed", moves_left)
		if moves_left <= 0:
			lost = true
			emit_signal("game_lost")

var score: int = 0 :
	set(value):
		score = value
		emit_signal("score_changed", score)

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

# Theme environment management - unified tileset, theme, and background
var available_themes: Array[Dictionary] = [
	{
		"name": "Green Classic", 
		"tileset_resource": "res://gameboard/resources/pipe_sprites.tres", 
		"theme_resource": "res://theme/green_theme.tres",
		"background_color": Color(0.85, 0.92, 0.87, 1.0),  # Light green tint
		"preview_face": 4
	},
	{
		"name": "Green Animated", 
		"tileset_resource": "res://gameboard/resources/green_tile_anim.tres", 
		"theme_resource": "res://theme/green_theme.tres",
		"background_color": Color(0.85, 0.92, 0.87, 1.0),  # Light green tint
		"preview_face": 4
	},
	{
		"name": "Blue Modern", 
		"tileset_resource": "res://gameboard/resources/tile1_sprites.tres", 
		"theme_resource": "res://theme/blue_theme.tres",
		"background_color": Color(0.917, 0.925, 0.951, 1.0),  # Light blue (current)
		"preview_face": 4
	},
	{
		"name": "Red Bold", 
		"tileset_resource": "res://gameboard/resources/tile_red_sprites.tres", 
		"theme_resource": "res://theme/red_theme.tres",
		"background_color": Color(0.95, 0.87, 0.85, 1.0),  # Light red tint
		"preview_face": 4
	}
]
var selected_theme_index: int = 1  # Default to Blue Modern

signal theme_changed(theme_data: Dictionary)

# Audio
var sounds: Dictionary = {}

func _ready():
	# Initialize default values
	reset_game()

func reset_game():
	moves_left = 100
	score = 0
	lost = false
	is_reward_earned = false

func add_score(points: int):
	score += points

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

# Theme environment management functions
func get_selected_theme_data() -> Dictionary:
	if selected_theme_index >= 0 and selected_theme_index < available_themes.size():
		return available_themes[selected_theme_index]
	return available_themes[1]  # Fallback to Blue Modern

func get_selected_tileset_resource() -> String:
	return get_selected_theme_data()["tileset_resource"]

func get_selected_theme_resource() -> String:
	return get_selected_theme_data()["theme_resource"]

func get_selected_background_color() -> Color:
	return get_selected_theme_data()["background_color"]

func set_selected_theme(index: int):
	if index >= 0 and index < available_themes.size():
		selected_theme_index = index
		var theme_data = available_themes[index]
		emit_signal("theme_changed", theme_data)

func get_theme_name(index: int) -> String:
	if index >= 0 and index < available_themes.size():
		return available_themes[index]["name"]
	return "Unknown"

func get_theme_count() -> int:
	return available_themes.size()
