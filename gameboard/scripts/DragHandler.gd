extends Node
class_name DragHandler

# Handles touch/mouse input for tile row/column dragging mechanics
# Based on playDragHandler.js pseudocode

signal drag_completed(drag_state: Dictionary)

# Animation state tracking
enum DragState { NONE, PREVIEW, HORIZONTAL, VERTICAL }
var drag_state: DragState = DragState.NONE
var displacement: Vector2 = Vector2.ZERO
var drag_direction: Vector2 = Vector2.ZERO
var start_position: Vector2
var current_displacement_factor: float = 0.0

# Legacy compatibility
var from: Vector2i  # Drag start tile position
var to: Vector2i    # Current drag target tile position
var state: String  # "horizontal", "vertical", or ""
var dragging: bool = false
var is_dragging: bool = false
var from_tile: Vector2i
var to_tile: Vector2i

var gameboard: GameBoard
var current_tile: Tile

func _ready():
	pass

func setup(board: GameBoard):
	gameboard = board

func start_drag(tile_pos: Vector2i):
	if gameboard.removing:
		return
	
	# Animation state initialization
	drag_state = DragState.PREVIEW
	displacement = Vector2.ZERO
	drag_direction = Vector2.ZERO
	start_position = Vector2(tile_pos.x * gameboard.tile_size, tile_pos.y * gameboard.tile_size)
	current_displacement_factor = 0.0
	
	# Legacy compatibility
	from = tile_pos
	to = tile_pos
	state = ""
	dragging = true
	is_dragging = true
	from_tile = tile_pos
	to_tile = tile_pos
	
	current_tile = gameboard.get_tile_at_position(tile_pos)

func _input(event: InputEvent):
	if not dragging:
		return
	
	if event is InputEventMouseMotion:
		handle_mouse_move(event)
	elif event is InputEventMouseButton:
		if not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			handle_mouse_up(event)

func handle_mouse_move(event: InputEventMouseMotion):
	if not current_tile:
		return
	
	# Calculate displacement using original algorithm
	var current_pos = Vector2(event.global_position.x, event.global_position.y)
	displacement = calculate_displacement(current_pos)
	
	# Update drag direction - fixed logic
	var movement = current_pos - start_position
	if movement.length() > 5.0:  # Threshold to prevent jitter
		if abs(movement.x) > abs(movement.y):
			# Horizontal movement - set horizontal drag direction
			drag_direction = Vector2(sign(movement.x), 0)
			if drag_state == DragState.PREVIEW:
				drag_state = DragState.HORIZONTAL
		else:
			# Vertical movement - set vertical drag direction  
			drag_direction = Vector2(0, sign(movement.y))
			if drag_state == DragState.PREVIEW:
				drag_state = DragState.VERTICAL
	
	# Legacy compatibility - update grid positions
	var new_to = screen_pos_to_grid_pos(event.global_position)
	if new_to != to and is_valid_grid_pos(new_to):
		to = new_to
		to_tile = new_to
	
	# Determine legacy drag state
	update_drag_state()

func handle_mouse_up(event: InputEventMouseButton):
	if not dragging:
		return
	
	var drag_info = {
		"state": state,
		"from": from,
		"to": to
	}
	
	# Reset drag state
	dragging = false
	is_dragging = false
	reset_drag_state()
	
	# Emit completion signal
	drag_completed.emit(drag_info)

func update_drag_state():
	if to == from:
		state = ""
		return
	
	var delta = to - from
	
	if state == "":
		if delta.x == 0 and delta.y != 0:
			state = "vertical"
		elif delta.y == 0 and delta.x != 0:
			state = "horizontal"
		elif delta.x != 0 and delta.y != 0:
			# For diagonal movement, default to horizontal
			state = "horizontal"

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
	# Immediate reset - no tween complications
	drag_state = DragState.NONE
	displacement = Vector2.ZERO
	drag_direction = Vector2.ZERO
	current_displacement_factor = 0.0
	from = Vector2i.ZERO
	to = Vector2i.ZERO
	state = ""
	from_tile = Vector2i.ZERO
	to_tile = Vector2i.ZERO
	current_tile = null

func get_drag_state() -> Dictionary:
	return {
		"state": state,
		"from": from,
		"to": to,
		"dragging": dragging,
		"drag_state": drag_state,
		"displacement": displacement,
		"drag_direction": drag_direction
	}

# Preview calculation for tile positioning during drag
func get_temp_position(grid_pos: Vector2i) -> Vector2i:
	var temp_x = grid_pos.x
	var temp_y = grid_pos.y
	
	# Handle vertical drag preview
	if state == "vertical" and from.x == grid_pos.x:
		temp_y += to.y - from.y
		temp_y = (temp_y + gameboard.board_height) % gameboard.board_height
	
	# Handle horizontal drag preview
	elif state == "horizontal" and from.y == grid_pos.y:
		temp_x += to.x - from.x
		temp_x = (temp_x + gameboard.board_width) % gameboard.board_width
	
	return Vector2i(temp_x, temp_y)

# Displacement calculation matching original logic
func calculate_displacement(current_pos: Vector2) -> Vector2:
	var distance = start_position.distance_to(current_pos)
	var tile_size = gameboard.tile_size
	# Make displacement more visible by using larger factor
	var normalized_distance = fmod(distance, tile_size) / tile_size
	var displacement_amount = drag_direction * normalized_distance * tile_size * 0.5  # Increased from 0.1
	return displacement_amount
