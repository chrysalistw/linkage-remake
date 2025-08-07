extends Control
class_name GameBoard

# Gameboard with drag detection and row/column rotation

@export var board_width: int = 6
@export var board_height: int = 8
@export var tile_size: int = 64

# Component managers
var board_manager: BoardManager
var rotation_handler: RotationHandler
var animation_manager: AnimationManager
var connection_manager: ConnectionManager
var drag_handler: DragHandler

# Convenience properties for compatibility
var board: Array:
	get:
		return board_manager.get_board() if board_manager else []
var tile_grid: Control:
	get:
		return board_manager.get_tile_grid() if board_manager else null

var removing: bool = false

# Track last applied displacement to avoid redundant rotation calls
var last_applied_displacement: Vector2i = Vector2i.ZERO

# Track drag state to clean up positions only once when drag ends
var was_dragging: bool = false

func _ready():
	# Add to gameboard group for GameState integration
	add_to_group("gameboard")
	
	# Initialize component managers
	setup_components()
	
	# Setup drag handler
	setup_drag_handler()
	
	# Connect to GameState signals
	if GameState:
		GameState.game_lost.connect(_on_game_over)
	
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

func initialize_board():
	# Clear existing board and re-enable input (fixes restart bug)
	board_manager.clear_board()
	enable_input()
	
	# Initialize board through manager
	board_manager.initialize_board()
	
	# Initial connection detection
	await get_tree().create_timer(0.1).timeout  # Give tiles time to initialize
	connection_manager.detect_and_highlight_connections()

func setup_drag_handler():
	drag_handler = DragHandler.new()
	add_child(drag_handler)
	drag_handler.setup(self)
	drag_handler.drag_completed.connect(_on_drag_completed)
	
	# Initialize animation manager with drag handler reference
	animation_manager = AnimationManager.new()
	animation_manager.initialize(self, board_manager, board_width, board_height, tile_size, drag_handler)
	
	# Connect to DragHandler's _input processing for visual updates
	set_process(true)

# Handle tile clicks - start drag
func _on_tile_clicked(tile: Tile):
	var pos = tile.get_grid_position()
	drag_handler.start_drag(pos)

# Handle drag completion - apply rotation
func _on_drag_completed(drag_state: Dictionary):
	# Check if game is over
	if GameState and GameState.lost:
		return  # Don't process moves when game is over
	
	# Clear drag visual indicators
	animation_manager.clear_drag_indicators()
	
	# Use Vector2 direction instead of legacy state strings
	var drag_direction = drag_state.get("drag_direction", Vector2.ZERO)
	var from_pos = drag_state.get("from", Vector2i.ZERO)
	var to_pos = drag_state.get("to", Vector2i.ZERO)
	
	# TODO: Fix rotation logic to match AnimationManager preview
	# Current issue: using raw position difference instead of grid_displacement
	# which causes mismatch between visual preview and actual rotation
	
	# if drag_direction.x != 0:
	# 	# Horizontal drag
	# 	var shift = to_pos.x - from_pos.x
	# 	rotation_handler.rotate_row(from_pos.y, shift)
	# elif drag_direction.y != 0:
	# 	# Vertical drag
	# 	var shift = to_pos.y - from_pos.y
	# 	rotation_handler.rotate_column(from_pos.x, shift)
	
	# Use one move per drag operation
	if GameState:
		GameState.use_move()
		print("Move used, moves left: ", GameState.moves_left)
	
	# Detect connections after move
	connection_manager.detect_and_highlight_connections()


# Debug helper functions - delegate to rotation handler
func print_row(row_index: int):
	rotation_handler.print_row(row_index)

func print_column(col_index: int):
	rotation_handler.print_column(col_index)


# Process function to update drag visual indicators and apply real-time rotations
func _process(_delta):
	var currently_dragging = drag_handler and drag_handler.dragging
	
	if currently_dragging:
		animation_manager.update_drag_indicators()
		
		# Apply real-time rotations to match visual preview
		apply_realtime_rotation()
		
		# Apply animated positions to tiles during drag
		animation_manager.apply_animated_positions()
		# Only update affected tiles for performance
		var affected_tiles = animation_manager.get_affected_tiles()
		for tile_pos in affected_tiles:
			var tile = board[tile_pos.y][tile_pos.x] as Tile
			if tile:
				tile.update_sprite_region()
		# Force redraw for visual indicators
		queue_redraw()
		
		was_dragging = true
	elif was_dragging:
		# Drag just ended - clean up positions once
		ensure_exact_tile_positions()
		was_dragging = false


func apply_realtime_rotation():
	"""Apply real-time rotation during drag to match AnimationManager preview"""
	if not drag_handler or not drag_handler.is_dragging:
		# Reset tracking when not dragging
		last_applied_displacement = Vector2i.ZERO
		return
		
	var start_tile = drag_handler.start_tile_pos
	var grid_displacement = drag_handler.grid_displacement
	var drag_direction = drag_handler.drag_direction
	
	# Only apply rotation if displacement has actually changed
	if grid_displacement == last_applied_displacement:
		return  # No change, skip expensive rotation
		
	# Update tracking
	last_applied_displacement = grid_displacement
	
	# Restore from baseline and apply rotation
	if drag_direction.x != 0:
		# Horizontal drag - rotate row
		restore_baseline_and_rotate_row(start_tile.y, grid_displacement.x)
	elif drag_direction.y != 0:
		# Vertical drag - rotate column  
		restore_baseline_and_rotate_column(start_tile.x, grid_displacement.y)

func restore_baseline_and_rotate_row(row_index: int, shift_amount: int):
	"""Restore row from baseline state and apply rotation"""
	if not drag_handler.baseline_board_state or row_index < 0 or row_index >= board_height:
		return
		
	var baseline = drag_handler.baseline_board_state
	var current_board = board_manager.get_board()
	
	# Restore row from baseline
	for x in board_width:
		current_board[row_index][x] = baseline[row_index][x]
	
	# Apply rotation if needed
	if shift_amount != 0:
		rotation_handler.rotate_row(row_index, shift_amount)

func restore_baseline_and_rotate_column(col_index: int, shift_amount: int):
	"""Restore column from baseline state and apply rotation"""  
	if not drag_handler.baseline_board_state or col_index < 0 or col_index >= board_width:
		return
		
	var baseline = drag_handler.baseline_board_state
	var current_board = board_manager.get_board()
	
	# Restore column from baseline
	for y in board_height:
		current_board[y][col_index] = baseline[y][col_index]
	
	# Apply rotation if needed
	if shift_amount != 0:
		rotation_handler.rotate_column(col_index, shift_amount)

func restore_from_baseline():
	"""Restore entire board from baseline state stored in drag handler"""
	if not drag_handler or not drag_handler.baseline_board_state:
		return
		
	var baseline = drag_handler.baseline_board_state
	var current_board = board_manager.get_board()
	
	# Restore entire board from baseline
	for y in board_height:
		for x in board_width:
			current_board[y][x] = baseline[y][x]
			var tile = baseline[y][x] as Tile
			if tile:
				tile.grid_x = x
				tile.grid_y = y
	
	# Rebuild tile grid to reflect restored positions
	board_manager.rebuild_tile_grid()
	print("[GameBoard] Board restored from baseline")

func ensure_exact_tile_positions():
	"""Ensure all tiles are positioned exactly at their grid coordinates (removes animation hints)"""
	var current_board = board_manager.get_board()
	for y in board_height:
		for x in board_width:
			var tile = current_board[y][x] as Tile
			if tile:
				# Set tile to exact grid position without any hint offsets
				tile.position = Vector2(x * tile_size, y * tile_size)

func get_tile_at_position(pos: Vector2i) -> Node:
	return board_manager.get_tile_at_position(pos)

# Animation Manager delegations
func get_predicted_tile_position(row: int, col: int) -> Vector2i:
	if animation_manager:
		return animation_manager.get_predicted_tile_position(row, col)
	return Vector2i(col, row)

func get_animated_tile_position(row: int, col: int) -> Vector2:
	if animation_manager:
		return animation_manager.get_animated_tile_position(row, col)
	return Vector2(col * tile_size, row * tile_size)


# Handle game over - disable input
func _on_game_over():
	print("Game Over! No more moves left.")
	# Disable drag handler to prevent further moves
	if drag_handler:
		drag_handler.set_process_input(false)
		drag_handler.reset_drag_state()

# Disable input during game over or other states
func disable_input():
	if drag_handler:
		drag_handler.set_process_input(false)
		drag_handler.reset_drag_state()

# Allow moves again (for restart functionality)
func enable_input():
	if drag_handler:
		drag_handler.set_process_input(true)


# Override _draw to add drag direction indicators
func _draw():
	if animation_manager:
		animation_manager.draw_drag_indicators()

# Debug control - enables debugging across all components
func enable_debug_mode():
	if drag_handler:
		drag_handler.enable_debug()
	if animation_manager:
		animation_manager.enable_debug()
	if rotation_handler:
		rotation_handler.enable_debug()
	print("[GameBoard] Debug mode enabled for all components")
