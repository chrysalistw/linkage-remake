extends Control
class_name GameBoard

# Gameboard with drag detection and row/column rotation

@export var board_width: int = 6
@export var board_height: int = 8
@export var tile_size: int = 64

# Component managers
var board_manager: BoardManager
var rotation_handler: RotationHandler
var connection_manager: ConnectionManager
var drag_handler: DragHandler
var click_audio: AudioStreamPlayer

# Convenience properties for compatibility
var board: Array:
	get:
		return board_manager.get_board() if board_manager else []
var tile_grid: Control:
	get:
		return board_manager.get_tile_grid() if board_manager else null

var removing: bool = false

# Rotation control - easily toggle rotation on/off for debugging
var rotation_enabled: bool = true

# Track drag state to clean up positions only once when drag ends
var was_dragging: bool = false

# Tile replacement tracking
var _replacement_tiles_remaining: int = 0
var _replacement_positions: Array = []

# Dynamic tile sizing
func calculate_optimal_tile_size():
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Reserve more space for UI elements and breathing room
	# Dashboard = ~25% height, wider margins = 25% width total
	var available_width = viewport_size.x * 0.9   # Use 75% of screen width
	var available_height = viewport_size.y * 0.9 # Use 55% of screen height
	
	# Calculate max tile size that fits the grid
	var max_tile_width = int(available_width / board_width)
	var max_tile_height = int(available_height / board_height)
	
	# Use the smaller dimension to ensure the grid fits
	var optimal_size = min(max_tile_width, max_tile_height)
	
	# Clamp to reasonable bounds (min 64px for readability, max 120px for performance)
	tile_size = clamp(optimal_size, 64, 120)
	
	# Update GameBoard size to fit the calculated tiles
	var total_width = tile_size * board_width
	var total_height = tile_size * board_height
	custom_minimum_size = Vector2(total_width, total_height)
	size = Vector2(total_width, total_height)
	
	print("Screen: ", viewport_size, " -> Tile size: ", tile_size, " GameBoard: ", size)

func update_tile_positions():
	# Update all existing tiles with new size and positions
	if board_manager:
		board_manager.update_tile_sizes_and_positions()

func _on_viewport_resized():
	# Recalculate tile size when screen changes (orientation, resize)
	calculate_optimal_tile_size()
	
	# Update existing tiles with new size and positions
	if board_manager:
		board_manager.tile_size = tile_size
		update_tile_positions()


func _ready():
	# Add to gameboard group for GameState integration
	add_to_group("gameboard")
	
	# Calculate optimal tile size based on screen
	calculate_optimal_tile_size()
	
	# Initialize component managers
	setup_components()
	
	# Setup drag handler
	setup_drag_handler()
	
	# Connect to GameState signals
	if GameState:
		GameState.game_lost.connect(_on_game_over)
	
	# Connect to viewport resize for responsive behavior
	get_viewport().size_changed.connect(_on_viewport_resized)
	
	# Initialize board
	initialize_board()
	
func setup_components():
	# Initialize component managers
	board_manager = BoardManager.new()
	board_manager.initialize(self, board_width, board_height, tile_size)
	
	rotation_handler = RotationHandler.new()
	rotation_handler.initialize(board_manager, board_width, board_height)
	
	connection_manager = ConnectionManager.new()
	connection_manager.initialize(board_manager, board_width, board_height)
	
	# Set connection manager reference in board manager for tile signal connections
	board_manager.set_connection_manager(connection_manager)
	
	# Set up audio system
	setup_audio()

# Debug input handler - press 'D' key to print board
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_D:
			if board_manager:
				board_manager.debug_print_board()

func initialize_board():
	board_manager.clear_board()
	enable_input()
	board_manager.initialize_board()
	
	# Debug: Print board after initialization
	board_manager.debug_print_board()
	
	await get_tree().create_timer(0.1).timeout
	connection_manager.detect_and_highlight_connections()
	

func setup_audio():
	click_audio = AudioStreamPlayer.new()
	add_child(click_audio)
	
	var click_sound = load("res://assets/sounds/trim_click_1.mp3")
	if click_sound:
		click_audio.stream = click_sound
		click_audio.volume_db = -12.0
		click_audio.pitch_scale = 1.0

func play_click_sound():
	if click_audio and click_audio.stream:
		click_audio.play()


func setup_drag_handler():
	drag_handler = DragHandler.new()
	add_child(drag_handler)
	drag_handler.setup(self)
	drag_handler.drag_completed.connect(_on_drag_completed)
	set_process(true)

func _on_tile_clicked(tile: Tile):
	var pos = tile.get_grid_position()
	drag_handler.start_drag(pos)
func _on_drag_completed(drag_state: Dictionary):
	if GameState and GameState.lost:
		return
	
	if GameState and drag_state.get("grid_displacement", Vector2i.ZERO) != Vector2i.ZERO:
		GameState.use_move()
	
	clear_all_drag_offsets()
	connection_manager.detect_and_highlight_connections()

func _process(_delta):
	if not drag_handler:
		return
	
	var currently_dragging = drag_handler.is_dragging
	
	if currently_dragging:
		# Apply visual drag offsets for smooth feedback
		apply_drag_visual_offsets()
		
		if rotation_enabled:
			var rotation_info = drag_handler.get_incremental_rotation()
			if rotation_info.get("has_increment", false):
				var increment = rotation_info.get("increment", Vector2i.ZERO)
				var drag_direction = rotation_info.get("drag_direction", Vector2.ZERO)
				var start_pos = rotation_info.get("start_pos", Vector2i.ZERO)
				
				if drag_direction.x != 0:
					rotation_handler.rotate_row(start_pos.y, increment.x)
					play_click_sound()
					add_snap_animation(start_pos.y, true)  # Row snap
				elif drag_direction.y != 0:
					rotation_handler.rotate_column(start_pos.x, increment.y)
					play_click_sound()
					add_snap_animation(start_pos.x, false) # Column snap

func clear_all_drag_offsets():
	var board = board_manager.get_board()
	for y in board_height:
		for x in board_width:
			var tile = board[y][x] as Tile
			if tile:
				tile.clear_drag_offset()

func apply_drag_visual_offsets():
	"""Apply visual drag offsets to tiles in the dragged row/column"""
	if not drag_handler or not drag_handler.is_dragging:
		return
	
	var drag_state = drag_handler.get_drag_state()
	var drag_direction = drag_state.get("drag_direction", Vector2.ZERO)
	var start_pos = drag_state.get("from", Vector2i.ZERO)
	var visual_offset = drag_handler.get_drag_visual_offset()
	
	if visual_offset == Vector2.ZERO:
		return
	
	var board = board_manager.get_board()
	
	# Apply offset to the entire row or column being dragged
	if drag_direction.x != 0:
		# Horizontal drag - apply to entire row
		var row_y = start_pos.y
		if row_y >= 0 and row_y < board_height:
			for x in board_width:
				var tile = board[row_y][x] as Tile
				if tile:
					tile.apply_drag_offset(visual_offset)
	elif drag_direction.y != 0:
		# Vertical drag - apply to entire column
		var col_x = start_pos.x
		if col_x >= 0 and col_x < board_width:
			for y in board_height:
				var tile = board[y][col_x] as Tile
				if tile:
					tile.apply_drag_offset(visual_offset)

func add_snap_animation(index: int, is_row: bool):
	"""Add brief snap animation when tiles overcome resistance threshold"""
	var board = board_manager.get_board()
	var snap_distance = 8.0  # Pixels to pull back before snap
	var snap_duration = 0.1  # Quick anticipation
	
	# Create anticipation offset opposite to drag direction
	var anticipation_offset = Vector2.ZERO
	if is_row:
		# Row animation - pull back horizontally
		var drag_dir = drag_handler.drag_direction.x if drag_handler else 1
		anticipation_offset.x = -snap_distance * sign(drag_dir)
	else:
		# Column animation - pull back vertically  
		var drag_dir = drag_handler.drag_direction.y if drag_handler else 1
		anticipation_offset.y = -snap_distance * sign(drag_dir)
	
	# Apply anticipation to affected tiles
	if is_row and index >= 0 and index < board_height:
		for x in board_width:
			var tile = board[index][x] as Tile
			if tile:
				animate_tile_snap(tile, anticipation_offset, snap_duration)
	elif not is_row and index >= 0 and index < board_width:
		for y in board_height:
			var tile = board[y][index] as Tile
			if tile:
				animate_tile_snap(tile, anticipation_offset, snap_duration)

func animate_tile_snap(tile: Tile, anticipation_offset: Vector2, duration: float):
	"""Animate individual tile with anticipation then snap back"""
	if not tile:
		return
	
	# Create a tween for the snap animation
	var tween = create_tween()
	
	# Apply anticipation offset briefly
	tile.apply_drag_offset(anticipation_offset)
	
	# Snap back to normal position after brief delay
	await get_tree().create_timer(duration).timeout
	tile.clear_drag_offset()

func get_tile_at_position(pos: Vector2i) -> Node:
	return board_manager.get_tile_at_position(pos)
func _on_game_over():
	if drag_handler:
		drag_handler.set_process_input(false)
		drag_handler.reset_drag_state()

func disable_input():
	if drag_handler:
		drag_handler.set_process_input(false)
		drag_handler.reset_drag_state()

func enable_input():
	if drag_handler:
		drag_handler.set_process_input(true)
func enable_rotation():
	rotation_enabled = true

func disable_rotation():
	rotation_enabled = false

func toggle_rotation():
	rotation_enabled = not rotation_enabled
	return rotation_enabled

func is_rotation_enabled() -> bool:
	return rotation_enabled

func apply_tile_replacement_reward():
	"""Replace half the tiles randomly with fade animation"""
	print("Applying tile replacement reward...")
	
	# Disable input during replacement
	disable_input()
	
	# Get all tile positions
	var all_positions = []
	for y in board_height:
		for x in board_width:
			all_positions.append(Vector2i(x, y))
	
	# Shuffle and select half the tiles
	all_positions.shuffle()
	var tiles_to_replace = all_positions.slice(0, all_positions.size() / 2)
	
	print("Replacing ", tiles_to_replace.size(), " tiles out of ", all_positions.size())
	
	# If no tiles to replace, re-enable input immediately
	if tiles_to_replace.size() == 0:
		print("No tiles to replace, re-enabling input")
		enable_input()
		return
	
	# Use a more reliable tracking system
	_replacement_tiles_remaining = tiles_to_replace.size()
	_replacement_positions = tiles_to_replace
	
	# Start fade animations for selected tiles
	for pos in tiles_to_replace:
		var tile = board_manager.get_tile_at_position(pos)
		if tile:
			# Connect to individual fade completion
			tile.fade_completed.connect(_on_replacement_tile_fade_complete, CONNECT_ONE_SHOT)
			tile.start_fade_out()
		else:
			# If tile doesn't exist, reduce counter
			_replacement_tiles_remaining -= 1

func _on_replacement_tile_fade_complete(tile: Tile):
	"""Called when a single replacement tile completes its fade"""
	_replacement_tiles_remaining -= 1
	print("Tile fade complete, remaining: ", _replacement_tiles_remaining)
	
	# Check if all tiles have completed fading
	if _replacement_tiles_remaining <= 0:
		_finish_tile_replacement()

func _finish_tile_replacement():
	"""Complete the tile replacement process"""
	print("All replacement fades complete, creating new tiles...")
	
	# Replace faded tiles with new random ones
	for pos in _replacement_positions:
		var tile = board_manager.get_tile_at_position(pos)
		if tile:
			# Remove old tile
			tile.queue_free()
			board_manager.get_board()[pos.y][pos.x] = null
			
			# Create new tile with random face
			await get_tree().process_frame  # Wait for old tile to be freed
			var new_tile = board_manager.create_tile(pos.x, pos.y)
	
	# Clear tracking variables
	_replacement_positions.clear()
	_replacement_tiles_remaining = 0
	
	# Small delay to let new tiles settle
	await get_tree().create_timer(0.1).timeout
	
	# Re-detect connections with new tiles
	connection_manager.detect_and_highlight_connections()
	
	# Re-enable input
	enable_input()
	
	print("Tile replacement reward complete!")
