extends Node
class_name DragHandler

# Handles touch/mouse input for tile row/column dragging mechanics
# Based on playDragHandler.js pseudocode

signal drag_completed(drag_state: Dictionary)

var from: Vector2i  # Drag start tile position
var to: Vector2i    # Current drag target tile position
var state: String  # "horizontal", "vertical", or ""
var displace: Vector2  # Visual displacement amount
var direction: Vector2  # Movement direction
var start_pos: Vector2  # Initial mouse/touch position
var dragging: bool = false

var gameboard: GameBoard
var current_tile: Tile

func setup(board: GameBoard):
	gameboard = board

func start_drag(tile_pos: Vector2i):
	if gameboard.removing:
		return
	
	from = tile_pos
	to = tile_pos
	state = ""
	dragging = true
	
	current_tile = gameboard.get_tile_at_position(tile_pos)
	if current_tile:
		start_pos = get_global_mouse_position()

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
	
	var current_pos = get_global_mouse_position()
	var movement = event.relative
	
	# Update target tile based on mouse position
	var new_to = screen_pos_to_grid_pos(current_pos)
	if new_to != to and is_valid_grid_pos(new_to):
		# Play sound on tile change (if available)
		# game_state.play_sound("click1")
		to = new_to
	
	# Determine drag state (horizontal vs vertical)
	update_drag_state()
	
	# Calculate movement direction
	update_movement_direction(movement)
	
	# Calculate visual displacement for smooth dragging
	calculate_displacement(current_pos)
	
	# Update visual feedback
	update_drag_visual()

func handle_mouse_up(event: InputEventMouseButton):
	if not dragging:
		return
	
	var drag_state = {
		"state": state,
		"from": from,
		"to": to
	}
	
	# Reset drag state
	dragging = false
	reset_drag_state()
	
	# Emit completion signal
	emit_signal("drag_completed", drag_state)

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

func update_movement_direction(movement: Vector2):
	if abs(movement.x) > abs(movement.y):
		direction = Vector2(sign(movement.x), 0)
	else:
		direction = Vector2(0, sign(movement.y))
	
	# Keep previous direction if no significant movement
	if direction == Vector2.ZERO:
		# direction remains the same
		pass

func calculate_displacement(current_pos: Vector2):
	var distance_vec = current_pos - start_pos
	var tile_size = gameboard.tile_size
	
	# Calculate displacement based on direction and distance
	var distance = distance_vec.length()
	var normalized_distance = fmod(distance, tile_size) / tile_size
	
	displace = Vector2(
		normalized_distance * direction.x * tile_size * 0.1,
		normalized_distance * direction.y * tile_size * 0.1
	)

func update_drag_visual():
	# This will be handled by the GameBoard's draw function
	# For now, we just store the displacement values
	pass

func screen_pos_to_grid_pos(screen_pos: Vector2) -> Vector2i:
	# Convert screen position to grid coordinates
	var tile_size = gameboard.tile_size
	var board_offset = gameboard.global_position
	
	var local_pos = screen_pos - board_offset
	var grid_x = int(local_pos.x / tile_size)
	var grid_y = int(local_pos.y / tile_size)
	
	return Vector2i(grid_x, grid_y)

func is_valid_grid_pos(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < gameboard.board_width and \
		   pos.y >= 0 and pos.y < gameboard.board_height

func reset_drag_state():
	from = Vector2i.ZERO
	to = Vector2i.ZERO
	state = ""
	displace = Vector2.ZERO
	direction = Vector2.ZERO
	start_pos = Vector2.ZERO
	current_tile = null

func get_drag_state() -> Dictionary:
	return {
		"state": state,
		"from": from,
		"to": to,
		"displace": displace,
		"direction": direction,
		"start": start_pos,
		"dragging": dragging
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
