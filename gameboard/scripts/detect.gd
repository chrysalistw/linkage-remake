extends Node
class_name LinkDetector

# Pipe connection detection algorithms
# Based on detect.js pseudocode

# Pipe connection mapping - defines which pipe types connect in each direction
const LINK_DIRECTIONS = {
	"up": {
		"target_offset": Vector2i(0, -1),
		"look_for": [0, 1, 4, 7]  # Pipe types that connect upward
	},
	"down": {
		"target_offset": Vector2i(0, 1),
		"look_for": [1, 2, 5, 8]  # Pipe types that connect downward
	},
	"right": {
		"target_offset": Vector2i(1, 0),
		"look_for": [6, 7, 8, 9]  # Pipe types that connect rightward
	},
	"left": {
		"target_offset": Vector2i(-1, 0),
		"look_for": [3, 4, 5, 6]  # Pipe types that connect leftward
	}
}

# Analysis tile structure
class AnalysisTile:
	var face: int
	var in_link: bool = true
	
	func _init(pipe_face: int):
		face = pipe_face

# Main detection algorithm
static func detect_links(board: Array) -> Array:
	if board.is_empty():
		return []
	
	var height = board.size()
	var width = board[0].size()
	
	# Create analysis copy of board
	var analysis_board = create_analysis_copy(board)
	var current_link = []
	
	# Check every tile as potential starting point
	for y in height:
		for x in width:
			current_link.clear()
			track_connection(analysis_board, x, y, current_link)
	
	# Convert to boolean map
	return convert_to_boolean_map(analysis_board, width, height)

# Create analysis copy of board
static func create_analysis_copy(board: Array) -> Array:
	var analysis_board = []
	
	for y in board.size():
		var row = []
		for x in board[y].size():
			var tile = board[y][x]
			if tile and tile.has_method("get_face"):
				row.append(AnalysisTile.new(tile.get_face()))
			elif tile and "face" in tile:
				row.append(AnalysisTile.new(tile.face))
			else:
				row.append(AnalysisTile.new(0))  # Default face
		analysis_board.append(row)
	
	return analysis_board

# Connection tracking algorithm
static func track_connection(analysis_board: Array, x: int, y: int, current_link: Array):
	current_link.append(Vector2i(x, y))
	
	var pipe_type = analysis_board[y][x].face
	var directions = []
	
	# Determine connection directions based on pipe type
	match pipe_type:
		0:  # Vertical end (down only)
			directions = ["down"]
		1:  # Vertical straight
			directions = ["up", "down"]
		2:  # Vertical end (up only)
			directions = ["up"]
		3:  # Horizontal end (right only)
			directions = ["right"]
		4:  # Corner (right-down)
			directions = ["right", "down"]
		5:  # Corner (right-up)
			directions = ["right", "up"]
		6:  # Horizontal straight
			directions = ["right", "left"]
		7:  # Corner (left-down)
			directions = ["left", "down"]
		8:  # Corner (left-up)
			directions = ["left", "up"]
		9:  # Horizontal end (left only)
			directions = ["left"]
		_:  # Invalid pipe type
			mark_link_as_disconnected(analysis_board, current_link)
			return
	
	# Look in all connection directions
	look_into_directions(analysis_board, x, y, directions, current_link)

# Directional connection checking
static func look_into_directions(analysis_board: Array, origin_x: int, origin_y: int, directions: Array, current_link: Array):
	for direction in directions:
		var target_offset = LINK_DIRECTIONS[direction].target_offset
		var target_x = origin_x + target_offset.x
		var target_y = origin_y + target_offset.y
		var valid_connections = LINK_DIRECTIONS[direction].look_for
		
		if not try_link(analysis_board, target_x, target_y, valid_connections):
			# Connection failed - mark entire current link as disconnected
			mark_link_as_disconnected(analysis_board, current_link)
		elif is_already_in_current_link(target_x, target_y, current_link):
			# Already visited in this link - valid loop connection
			continue
		else:
			# Valid connection - recursively track from target
			track_connection(analysis_board, target_x, target_y, current_link)

# Connection validation
static func try_link(analysis_board: Array, x: int, y: int, valid_pipe_types: Array) -> bool:
	# Check bounds
	if y < 0 or y >= analysis_board.size():
		return false
	if x < 0 or x >= analysis_board[y].size():
		return false
	
	var target_pipe_type = analysis_board[y][x].face
	return target_pipe_type in valid_pipe_types

# Check if position is already in current link
static func is_already_in_current_link(x: int, y: int, current_link: Array) -> bool:
	for pos in current_link:
		if pos.x == x and pos.y == y:
			return true
	return false

# Mark entire link as disconnected
static func mark_link_as_disconnected(analysis_board: Array, current_link: Array):
	for pos in current_link:
		if pos.y >= 0 and pos.y < analysis_board.size() and pos.x >= 0 and pos.x < analysis_board[pos.y].size():
			analysis_board[pos.y][pos.x].in_link = false

# Convert analysis board to boolean map
static func convert_to_boolean_map(analysis_board: Array, width: int, height: int) -> Array:
	var boolean_map = []
	
	for y in height:
		var row = []
		for x in width:
			if y < analysis_board.size() and x < analysis_board[y].size():
				row.append(analysis_board[y][x].in_link)
			else:
				row.append(false)
		boolean_map.append(row)
	
	return boolean_map

# Remove links and handle scoring (async)
static func remove_links(gameboard: GameBoard, links: Array, without_pause: bool = false):
	# Check if any links exist
	var has_links = false
	for row in links:
		if true in row:
			has_links = true
			break
	
	if not has_links:
		return  # No links to remove
	
	gameboard.removing = true
	
	if not without_pause:
		await gameboard.get_tree().create_timer(0.5).timeout  # Animation delay
	
	# Replace all linked tiles and calculate score
	var score_increase = 0
	for y in links.size():
		for x in links[y].size():
			if links[y][x] == true:
				# Replace with random new tile
				var tile = gameboard.get_tile_at_position(Vector2i(x, y))
				if tile:
					tile.set_face(randi() % 10)
					if not without_pause:
						score_increase += 1
	
	# Update game state
	var game_state = GameState.instance
	if game_state:
		game_state.add_score(score_increase)
		# Add bonus moves (1 move per 3 tiles removed)
		var bonus_moves = score_increase / 3
		game_state.moves_left += bonus_moves
	
	gameboard.removing = false
	
	# Recursive detection and removal for chain reactions
	if not without_pause:
		await gameboard.get_tree().create_timer(0.3).timeout  # Animation delay
	
	var new_links = detect_links(gameboard.board)
	if has_any_links(new_links):
		await remove_links(gameboard, new_links, without_pause)

# Helper function to check if any links exist
static func has_any_links(links: Array) -> bool:
	for row in links:
		if true in row:
			return true
	return false
