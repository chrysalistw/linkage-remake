extends Control

# PopupManager - Manages popup text animations for score and move changes
# Handles positioning and prevents overlapping popups

const PopupText = preload("res://ui/PopupText.gd")

var dashboard_reference: Control
var score_display_reference: Control
var moves_display_reference: Control

var active_popups: Array[Node] = []
var popup_offset_counter: int = 0

var last_score: int = 0
var last_moves: int = 100

func _ready():
	# Find references to dashboard components
	_setup_references()
	
	# Connect to GameState signals - both regular and early signals
	GameState.score_changed.connect(_on_score_changed)
	GameState.moves_changed.connect(_on_moves_changed)
	GameState.tiles_about_to_score.connect(_on_tiles_about_to_score)
	GameState.moves_about_to_be_awarded.connect(_on_moves_about_to_be_awarded)

func _setup_references():
	# Find dashboard and display references
	var play_screen = get_parent()
	if play_screen.has_node("Dashboard/HBoxContainer/VBoxContainer/ScoreDisplay"):
		score_display_reference = play_screen.get_node("Dashboard/HBoxContainer/VBoxContainer/ScoreDisplay")
	if play_screen.has_node("Dashboard/HBoxContainer/VBoxContainer/MovesDisplay"):
		moves_display_reference = play_screen.get_node("Dashboard/HBoxContainer/VBoxContainer/MovesDisplay")

func _on_score_changed(new_score: int):
	# Update tracking but don't show popup (early signals handle this)
	last_score = new_score

func _on_moves_changed(new_moves: int):
	# Update tracking but don't show popup (early signals handle this)  
	last_moves = new_moves


# Early signal handlers - trigger popups immediately when fade starts
func _on_tiles_about_to_score(tile_count: int):
	_create_popup("+" + str(tile_count), PopupText.PopupType.SCORE, _get_score_popup_position())

func _on_moves_about_to_be_awarded(move_count: int):
	_create_popup("+" + str(move_count), PopupText.PopupType.MOVES, _get_moves_popup_position())

func _create_popup(text_content: String, popup_type: PopupText.PopupType, start_position: Vector2):
	# Create new popup text label
	var popup = Label.new()
	popup.set_script(PopupText)
	
	# Add to scene tree
	add_child(popup)
	active_popups.append(popup)
	
	# Setup and start animation
	popup.setup_popup(text_content, popup_type, start_position)
	
	# Clean up reference when popup is done
	popup.tree_exiting.connect(_on_popup_cleanup.bind(popup))

func _on_popup_cleanup(popup: Node):
	if popup in active_popups:
		active_popups.erase(popup)

func _get_score_popup_position() -> Vector2:
	if score_display_reference:
		var global_pos = score_display_reference.global_position
		var size = score_display_reference.size
		# Position to the right of the score display with slight vertical offset for multiple popups
		var offset_x = size.x + 30
		var offset_y = size.y / 2 - 10 + (popup_offset_counter * 15)
		popup_offset_counter = (popup_offset_counter + 1) % 4  # Cycle through 4 positions
		return Vector2(global_pos.x + offset_x, global_pos.y + offset_y)
	else:
		# Fallback position if reference not found
		return Vector2(450, 120)

func _get_moves_popup_position() -> Vector2:
	if moves_display_reference:
		var global_pos = moves_display_reference.global_position
		var size = moves_display_reference.size
		# Position to the right of the moves display with slight vertical offset for multiple popups
		var offset_x = size.x + 30
		var offset_y = size.y / 2 - 10 + (popup_offset_counter * 15)
		popup_offset_counter = (popup_offset_counter + 1) % 4  # Cycle through 4 positions
		return Vector2(global_pos.x + offset_x, global_pos.y + offset_y)
	else:
		# Fallback position if reference not found
		return Vector2(450, 80)
