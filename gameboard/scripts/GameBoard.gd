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

# Note: Real-time rotation disabled - drag is purely visual until completion

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
	
	# Debug: Print board state before rotation
	var from_pos = drag_state.get("from", Vector2i.ZERO)
	var drag_direction = drag_state.get("drag_direction", Vector2.ZERO)
	print("=== BOARD STATE BEFORE ROTATION ===")
	if drag_direction.x != 0:
		print_row(from_pos.y)
	elif drag_direction.y != 0:
		print_column(from_pos.x)
	
	# Get grid displacement from drag handler for accurate rotation
	var grid_displacement = drag_state.get("grid_displacement", Vector2i.ZERO)
	
	# DEBUGGING: Rotation temporarily disabled to isolate drag visual issues
	# Apply rotation using grid displacement (matches visual preview)
	# if grid_displacement != Vector2i.ZERO:
	#	if drag_direction.x != 0:
	#		# Horizontal drag
	#		rotation_handler.rotate_row(from_pos.y, grid_displacement.x)
	#		print("Applied horizontal rotation: row %d, shift %d" % [from_pos.y, grid_displacement.x])
	#	elif drag_direction.y != 0:
	#		# Vertical drag
	#		rotation_handler.rotate_column(from_pos.x, grid_displacement.y)
	#		print("Applied vertical rotation: col %d, shift %d" % [from_pos.x, grid_displacement.y])
	# else:
	#	print("No rotation applied - grid displacement was zero")
	
	print("DEBUGGING: Rotation cut out to isolate drag visual problem - grid_displacement: %s" % grid_displacement)
	
	# Use one move per drag operation
	if GameState:
		GameState.use_move()
		print("Move used, moves left: ", GameState.moves_left)
	
	# Detect connections after move
	connection_manager.detect_and_highlight_connections()


# Debug helper functions - delegate to rotation handler
func print_row(row_index: int):
	# rotation_handler.print_row(row_index)
	pass

func print_column(col_index: int):
	# rotation_handler.print_column(col_index)
	pass


# Process function to update drag visual indicators and apply real-time rotations
func _process(_delta):
	var currently_dragging = drag_handler and drag_handler.dragging
	
	if currently_dragging:
		animation_manager.update_drag_indicators()
		
		# Apply animated positions to tiles during drag (visual only)
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
		# Drag just ended - ensure tiles are at exact grid positions
		ensure_exact_tile_positions()
		was_dragging = false


# Real-time rotation disabled - dragging is now purely visual
# Actual rotation happens only on drag completion in _on_drag_completed()

# Baseline restoration functions disabled - no longer modify board during drag
# func restore_baseline_and_rotate_row(row_index: int, shift_amount: int):
#	"""Restore row from baseline state and apply rotation"""
#	if not drag_handler.baseline_board_state or row_index < 0 or row_index >= board_height:
#		return
#		
#	var baseline = drag_handler.baseline_board_state
#	var current_board = board_manager.get_board()
#	
#	# Restore row from baseline
#	for x in board_width:
#		current_board[row_index][x] = baseline[row_index][x]
#	
#	# Apply rotation if needed
#	if shift_amount != 0:
#		# rotation_handler.rotate_row(row_index, shift_amount)
#		pass

# func restore_baseline_and_rotate_column(col_index: int, shift_amount: int):
#	"""Restore column from baseline state and apply rotation"""  
#	if not drag_handler.baseline_board_state or col_index < 0 or col_index >= board_width:
#		return
#		
#	var baseline = drag_handler.baseline_board_state
#	var current_board = board_manager.get_board()
#	
#	# Restore column from baseline
#	for y in board_height:
#		current_board[y][col_index] = baseline[y][col_index]
#	
#	# Apply rotation if needed
#	if shift_amount != 0:
#		# rotation_handler.rotate_column(col_index, shift_amount)
#		pass

# Baseline restoration disabled - no longer needed with pure visual drag system
# func restore_from_baseline():
#	"""Restore entire board from baseline state stored in drag handler"""
#	if not drag_handler or not drag_handler.baseline_board_state:
#		return
#		
#	var baseline = drag_handler.baseline_board_state
#	var current_board = board_manager.get_board()
#	
#	# Restore entire board from baseline
#	for y in board_height:
#		for x in board_width:
#			current_board[y][x] = baseline[y][x]
#			var tile = baseline[y][x] as Tile
#			if tile:
#				tile.grid_x = x
#				tile.grid_y = y
#	
#	# Rebuild tile grid to reflect restored positions
#	board_manager.rebuild_tile_grid()
#	print("[GameBoard] Board restored from baseline")

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
		# rotation_handler.enable_debug()
		pass
	print("[GameBoard] Debug mode enabled for all components")
