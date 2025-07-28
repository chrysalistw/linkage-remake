extends Node
class_name GameState

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

# Audio
var sounds: Dictionary = {}

# Static instance for singleton pattern
static var instance: GameState

func _init():
	if instance == null:
		instance = self
	else:
		queue_free()

func _ready():
	# Set up as singleton
	if instance != self:
		return
	
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

# Expose functions to window for Android integration
func _notification(what):
	if what == NOTIFICATION_READY:
		# Expose restart function
		if Engine.has_singleton("JavaScriptBridge"):
			var js = Engine.get_singleton("JavaScriptBridge")
			js.get_interface("window").restart = restart_game
			js.get_interface("window").rewardEarned = _on_reward_earned
			js.get_interface("window").reward = _on_reward_requested

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
