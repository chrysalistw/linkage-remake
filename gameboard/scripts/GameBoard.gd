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

# Debug: Store before-drag state for comparison
var debug_before_drag_data: Array = []
var debug_before_drag_positions: Array = []
var debug_dragged_index: int = -1
var debug_drag_type: String = ""

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
	
	# Capture before-drag state for debug comparison
	debug_capture_before_drag_state(pos)
	
	drag_handler.start_drag(pos)

# Handle drag completion - apply rotation
func _on_drag_completed(drag_state: Dictionary):
	# Check if game is over
	if GameState and GameState.lost:
		return  # Don't process moves when game is over
	
	# Clear drag visual indicators and animation offsets
	print("[GameBoard] Clearing drag indicators...")
	animation_manager.clear_drag_indicators()
	print("[GameBoard] Resetting tile positions...")
	animation_manager.reset_tile_positions()
	print("[GameBoard] Animation cleanup complete")
	
	# Extract drag information for logging
	var from_pos = drag_state.get("from", Vector2i.ZERO)
	var to_pos = drag_state.get("to", Vector2i.ZERO)
	var drag_direction = drag_state.get("drag_direction", Vector2.ZERO)
	var grid_displacement = drag_state.get("grid_displacement", Vector2i.ZERO)
	var drag_state_str = drag_state.get("state", "")
	
	# Print detailed drag information
	print("=== DRAG COMPLETED ===")
	print("From: (%d,%d) → To: (%d,%d)" % [from_pos.x, from_pos.y, to_pos.x, to_pos.y])
	print("Direction: ", drag_direction, " | State: ", drag_state_str)
	print("Grid displacement: ", grid_displacement)
	
	# Print before/after comparison
	if drag_direction.x != 0:
		print("Horizontal drag - Row %d comparison:" % from_pos.y)
		debug_print_before_after_comparison("row", from_pos.y)
	elif drag_direction.y != 0:
		print("Vertical drag - Column %d comparison:" % from_pos.x)
		debug_print_before_after_comparison("column", from_pos.x)
	
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
	
	# Rotation disabled - visual animation now handled by offset system
	
	# Use one move per drag operation
	if GameState:
		var moves_before = GameState.moves_left
		GameState.use_move()
		print("Move used: %d → %d moves remaining" % [moves_before, GameState.moves_left])
	
	# Detect connections after move
	connection_manager.detect_and_highlight_connections()
	print("=== END DRAG ===\n")
	


# Debug helper functions for printing board data
func debug_print_row(row_index: int):
	if row_index < 0 or row_index >= board_height:
		print("  Invalid row index: %d" % row_index)
		return
	
	var board = board_manager.get_board()
	var row_data = []
	var row_positions = []
	for x in board_width:
		var tile = board[row_index][x] as Tile
		if tile:
			row_data.append(tile.face)
			row_positions.append("(%d,%d)" % [tile.grid_x, tile.grid_y])
		else:
			row_data.append("null")
			row_positions.append("null")
	
	print("  Faces: ", row_data)
	print("  Grid positions: ", row_positions)

func debug_print_column(col_index: int):
	if col_index < 0 or col_index >= board_width:
		print("  Invalid column index: %d" % col_index)
		return
	
	var board = board_manager.get_board()
	var col_data = []
	var col_positions = []
	for y in board_height:
		var tile = board[y][col_index] as Tile
		if tile:
			col_data.append(tile.face)
			col_positions.append("(%d,%d)" % [tile.grid_x, tile.grid_y])
		else:
			col_data.append("null")
			col_positions.append("null")
	
	print("  Faces: ", col_data)
	print("  Grid positions: ", col_positions)

func debug_capture_before_drag_state(clicked_pos: Vector2i):
	"""Capture the state of row/column before drag starts for comparison"""
	debug_before_drag_data.clear()
	debug_before_drag_positions.clear()
	debug_dragged_index = -1
	debug_drag_type = ""
	
	var board = board_manager.get_board()
	
	# We don't know the drag direction yet, so capture both row and column
	# The actual comparison will determine which one was dragged
	var row_data = []
	var row_positions = []
	var col_data = []
	var col_positions = []
	
	# Capture row data
	for x in board_width:
		var tile = board[clicked_pos.y][x] as Tile
		if tile:
			row_data.append(tile.face)
			row_positions.append("(%d,%d)" % [tile.grid_x, tile.grid_y])
		else:
			row_data.append("null")
			row_positions.append("null")
	
	# Capture column data  
	for y in board_height:
		var tile = board[y][clicked_pos.x] as Tile
		if tile:
			col_data.append(tile.face)
			col_positions.append("(%d,%d)" % [tile.grid_x, tile.grid_y])
		else:
			col_data.append("null")
			col_positions.append("null")
	
	# Store both for later comparison
	debug_before_drag_data = [row_data, col_data]
	debug_before_drag_positions = [row_positions, col_positions]

func debug_print_before_after_comparison(type: String, index: int):
	"""Print before/after comparison of dragged row or column"""
	if debug_before_drag_data.size() != 2:
		print("  No before-drag data captured")
		return
	
	var board = board_manager.get_board()
	var before_data = []
	var before_positions = []
	var after_data = []
	var after_positions = []
	
	if type == "row":
		# Get before data (row is index 0 in stored arrays)
		before_data = debug_before_drag_data[0]
		before_positions = debug_before_drag_positions[0]
		
		# Get current after data
		for x in board_width:
			var tile = board[index][x] as Tile
			if tile:
				after_data.append(tile.face)
				after_positions.append("(%d,%d)" % [tile.grid_x, tile.grid_y])
			else:
				after_data.append("null")
				after_positions.append("null")
				
	elif type == "column":
		# Get before data (column is index 1 in stored arrays)
		before_data = debug_before_drag_data[1]
		before_positions = debug_before_drag_positions[1]
		
		# Get current after data
		for y in board_height:
			var tile = board[y][index] as Tile
			if tile:
				after_data.append(tile.face)
				after_positions.append("(%d,%d)" % [tile.grid_x, tile.grid_y])
			else:
				after_data.append("null")
				after_positions.append("null")
	
	# Print comparison
	print("  BEFORE faces: ", before_data)
	print("  AFTER  faces: ", after_data)
	print("  BEFORE positions: ", before_positions)
	print("  AFTER  positions: ", after_positions)
	
	# Check if anything actually changed
	var data_changed = (before_data != after_data)
	var positions_changed = (before_positions != after_positions)
	print("  Data changed: ", data_changed, " | Positions changed: ", positions_changed)
	
	# Also check actual visual positions of tiles
	print("  Current visual positions:")
	if type == "row":
		for x in board_width:
			var tile = board[index][x] as Tile
			if tile:
				print("    Tile[%d,%d] face:%d visual_pos: %s base_pos: %s offset: %s" % [
					x, index, tile.face, tile.position, tile.get_base_position(), tile.animation_offset])
	elif type == "column":
		for y in board_height:
			var tile = board[y][index] as Tile
			if tile:
				print("    Tile[%d,%d] face:%d visual_pos: %s base_pos: %s offset: %s" % [
					index, y, tile.face, tile.position, tile.get_base_position(), tile.animation_offset])


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
		# Drag just ended - clear animation offsets to restore base positions
		print("[GameBoard] _process detected drag end - resetting positions")
		animation_manager.reset_tile_positions()
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
