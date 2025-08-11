extends Node
class_name DragHandler

# Handles touch/mouse input for tile row/column dragging mechanics
# Based on playDragHandler.js pseudocode

signal drag_completed(drag_state: Dictionary)

# Drag state tracking - simplified and unified
enum DragState { NONE, PREVIEW, HORIZONTAL, VERTICAL }
var drag_state: DragState = DragState.NONE
var is_dragging: bool = false

# Core drag data
var start_tile_pos: Vector2i
var start_mouse_pos: Vector2
var current_mouse_pos: Vector2
var drag_direction: Vector2 = Vector2.ZERO
var pixel_displacement: Vector2 = Vector2.ZERO
var grid_displacement: Vector2i = Vector2i.ZERO

# Baseline state tracking for real-time rotation
var baseline_board_state: Array = []

# Real-time rotation tracking
var last_applied_grid_displacement: Vector2i = Vector2i.ZERO
var total_rotations_applied: Vector2i = Vector2i.ZERO

# Legacy compatibility properties
var dragging: bool:
	get: return is_dragging
var from: Vector2i:
	get: return start_tile_pos
var to: Vector2i:
	get: return get_target_tile_pos()
var state: String:
	get: return get_state_string()
var from_tile: Vector2i:
	get: return start_tile_pos
var to_tile: Vector2i:
	get: return get_target_tile_pos()

var gameboard: GameBoard
var current_tile: Tile

func _ready():
	pass

func setup(board: GameBoard):
	gameboard = board

# Helper methods for legacy compatibility
func get_target_tile_pos() -> Vector2i:
	if not is_dragging:
		return start_tile_pos
	return screen_pos_to_grid_pos(current_mouse_pos)

func get_state_string() -> String:
	match drag_state:
		DragState.HORIZONTAL:
			return "horizontal"
		DragState.VERTICAL:
			return "vertical"
		_:
			return ""

func start_drag(tile_pos: Vector2i):
	if gameboard.removing:
		return
	
	# Initialize drag state
	drag_state = DragState.PREVIEW
	is_dragging = true
	
	# Store positions
	start_tile_pos = tile_pos
	start_mouse_pos = get_viewport().get_mouse_position()
	current_mouse_pos = start_mouse_pos
	
	# Reset vectors
	drag_direction = Vector2.ZERO
	pixel_displacement = Vector2.ZERO
	grid_displacement = Vector2i.ZERO
	
	# Reset real-time rotation tracking
	last_applied_grid_displacement = Vector2i.ZERO
	total_rotations_applied = Vector2i.ZERO
	
	# Store baseline board state for real-time rotation
	store_baseline_board_state()
	
	current_tile = gameboard.get_tile_at_position(tile_pos)
	
	

func _input(event: InputEvent):
	if not is_dragging:
		return
	
	if event is InputEventMouseMotion:
		handle_mouse_move(event)
	elif event is InputEventMouseButton:
		if not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			handle_mouse_up(event)
	elif event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			cancel_drag()

func handle_mouse_move(event: InputEventMouseMotion):
	if not current_tile:
		return
	
	# Update current mouse position
	current_mouse_pos = event.global_position
	
	# Detect and update drag direction
	detect_drag_direction()
	
	# Calculate pixel displacement for animations
	pixel_displacement = current_mouse_pos - start_mouse_pos
	
	# Calculate grid displacement based on drag direction
	calculate_grid_displacement()

func handle_mouse_up(event: InputEventMouseButton):
	if not is_dragging:
		return
	
	var drag_info = {
		"state": get_state_string(),
		"from": start_tile_pos,
		"to": get_target_tile_pos(),
		"drag_direction": drag_direction,
		"grid_displacement": grid_displacement
	}
	
	# Reset drag state
	reset_drag_state()
	
	# Emit completion signal
	drag_completed.emit(drag_info)

func detect_drag_direction():
	"""Detects drag direction based on mouse movement and updates drag state"""
	var movement = current_mouse_pos - start_mouse_pos
	var movement_threshold = 8.0  # Minimum pixels to determine direction
	
	if movement.length() < movement_threshold:
		return  # Not enough movement to determine direction
	
	# Only change direction during preview state to avoid state flipping
	if drag_state != DragState.PREVIEW:
		return
	
	var old_state = drag_state
	
	# Determine primary movement direction
	if abs(movement.x) > abs(movement.y):
		# Horizontal movement dominates
		drag_direction = Vector2(sign(movement.x), 0)
		drag_state = DragState.HORIZONTAL
	else:
		# Vertical movement dominates  
		drag_direction = Vector2(0, sign(movement.y))
		drag_state = DragState.VERTICAL
	
	if old_state != drag_state:
		pass

# Simplified drag implementation - no smooth visuals needed

func screen_pos_to_grid_pos(screen_pos: Vector2) -> Vector2i:
	# Convert screen position to grid coordinates
	var tile_size = gameboard.tile_size
	var board_offset = gameboard.tile_grid.global_position
	
	var local_pos = screen_pos - board_offset
	var grid_x = int(local_pos.x / tile_size)
	var grid_y = int(local_pos.y / tile_size)
	
	return Vector2i(grid_x, grid_y)

func is_valid_grid_pos(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < gameboard.board_width and \
		   pos.y >= 0 and pos.y < gameboard.board_height

func reset_drag_state():
	# Reset to initial state
	drag_state = DragState.NONE
	is_dragging = false
	
	# Clear positions and vectors
	start_tile_pos = Vector2i.ZERO
	start_mouse_pos = Vector2.ZERO
	current_mouse_pos = Vector2.ZERO
	drag_direction = Vector2.ZERO
	pixel_displacement = Vector2.ZERO
	grid_displacement = Vector2i.ZERO
	
	# Clear baseline state
	baseline_board_state.clear()
	
	current_tile = null

func get_drag_state() -> Dictionary:
	return {
		"state": get_state_string(),
		"from": start_tile_pos,
		"to": get_target_tile_pos(),
		"dragging": is_dragging,
		"drag_state": drag_state,
		"pixel_displacement": pixel_displacement,
		"drag_direction": drag_direction,
		"grid_displacement": grid_displacement
	}


func cancel_drag():
	"""Cancel current drag and restore board to baseline state"""
	if not is_dragging:
		return
		
	
	# Restore board from baseline
	if gameboard.has_method("restore_from_baseline"):
		gameboard.restore_from_baseline()
	
	# Reset drag state
	reset_drag_state()

func store_baseline_board_state():
	"""Store a deep copy of the current board state for baseline restoration"""
	baseline_board_state.clear()
	if not gameboard or not gameboard.board:
		return
		
	var board = gameboard.board
	for row in board:
		var row_copy = []
		for tile in row:
			row_copy.append(tile)  # Store tile references
		baseline_board_state.append(row_copy)
	

# Debug infrastructure
var debug_enabled: bool = true

func enable_debug():
	debug_enabled = true

func debug_print(message: String):
	if debug_enabled:
		print("[DragHandler] ", message)

func calculate_grid_displacement():
	"""Calculates which grid positions the drag moves from/to"""
	if drag_state == DragState.PREVIEW or not is_dragging:
		grid_displacement = Vector2i.ZERO
		return
	
	var current_grid_pos = screen_pos_to_grid_pos(current_mouse_pos)
	
	match drag_state:
		DragState.HORIZONTAL:
			# Calculate horizontal grid displacement
			var grid_diff = current_grid_pos.x - start_tile_pos.x
			grid_displacement = Vector2i(grid_diff, 0)
		DragState.VERTICAL:
			# Calculate vertical grid displacement
			var grid_diff = current_grid_pos.y - start_tile_pos.y
			grid_displacement = Vector2i(0, grid_diff)
		_:
			grid_displacement = Vector2i.ZERO

func debug_state():
	if debug_enabled:
		debug_print("State: %s | Direction: %s | Pixel: %s | Grid: %s" % [
			get_state_string(), 
			drag_direction, 
			pixel_displacement,
			grid_displacement
		])

func get_incremental_rotation() -> Dictionary:
	"""Get the incremental rotation since last check (for real-time updates)"""
	var current_displacement = grid_displacement
	var increment = current_displacement - last_applied_grid_displacement
	
	if increment != Vector2i.ZERO:
		# Update tracking
		last_applied_grid_displacement = current_displacement
		total_rotations_applied += increment
		
		return {
			"has_increment": true,
			"increment": increment,
			"drag_direction": drag_direction,
			"start_pos": start_tile_pos
		}
	
	return {"has_increment": false}
