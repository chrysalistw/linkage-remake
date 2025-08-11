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
	
	# Print initial rotation status
	print_rotation_status()

func setup_drag_handler():
	drag_handler = DragHandler.new()
	add_child(drag_handler)
	drag_handler.setup(self)
	drag_handler.drag_completed.connect(_on_drag_completed)
	

# Handle tile clicks - start drag
func _on_tile_clicked(tile: Tile):
	var pos = tile.get_grid_position()
	drag_handler.start_drag(pos)

# Handle drag completion - apply rotation
func _on_drag_completed(drag_state: Dictionary):
	# Check if game is over
	if GameState and GameState.lost:
		return  # Don't process moves when game is over
	
	
	# Extract drag information for rotation
	var from_pos = drag_state.get("from", Vector2i.ZERO)
	var drag_direction = drag_state.get("drag_direction", Vector2.ZERO)
	var grid_displacement = drag_state.get("grid_displacement", Vector2i.ZERO)
	
	# Apply rotation if enabled
	if rotation_enabled and grid_displacement != Vector2i.ZERO:
		if drag_direction.x != 0:
			# Horizontal drag - rotate row
			rotation_handler.rotate_row(from_pos.y, grid_displacement.x)
			print("Applied horizontal rotation: row %d, shift %d" % [from_pos.y, grid_displacement.x])
		elif drag_direction.y != 0:
			# Vertical drag - rotate column
			rotation_handler.rotate_column(from_pos.x, grid_displacement.y)
			print("Applied vertical rotation: col %d, shift %d" % [from_pos.x, grid_displacement.y])
	else:
		if not rotation_enabled:
			print("Rotation disabled - no changes applied")
		elif grid_displacement == Vector2i.ZERO:
			print("No rotation needed - grid displacement was zero")
	
	# Use one move per drag operation
	if GameState:
		GameState.use_move()
	
	# Detect connections after move
	connection_manager.detect_and_highlight_connections()
	






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



# Debug control - enables debugging across all components
func enable_debug_mode():
	if drag_handler:
		drag_handler.enable_debug()
	if rotation_handler:
		# rotation_handler.enable_debug()
		pass

# Rotation control methods
func enable_rotation():
	"""Enable board rotation when dragging"""
	rotation_enabled = true
	print("[GameBoard] Rotation enabled")

func disable_rotation():
	"""Disable board rotation when dragging (drag will only use moves)"""
	rotation_enabled = false
	print("[GameBoard] Rotation disabled")

func toggle_rotation():
	"""Toggle rotation on/off and return current state"""
	rotation_enabled = not rotation_enabled
	print("[GameBoard] Rotation %s" % ("enabled" if rotation_enabled else "disabled"))
	return rotation_enabled

func is_rotation_enabled() -> bool:
	"""Check if rotation is currently enabled"""
	return rotation_enabled

func print_rotation_status():
	"""Print current rotation status for debugging"""
	print("[GameBoard] Rotation is currently %s" % ("ENABLED" if rotation_enabled else "DISABLED"))
