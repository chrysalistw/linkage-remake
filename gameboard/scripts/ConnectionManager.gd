extends RefCounted
class_name ConnectionManager

var board_width: int
var board_height: int
var board_manager: BoardManager

# Track completed fades for batch processing
var faded_tiles_count: int = 0
var expected_fades: int = 0

func initialize(manager: BoardManager, width: int, height: int):
	board_manager = manager
	board_width = width
	board_height = height

func detect_and_highlight_connections():
	# Clear previous connection highlights
	clear_connection_highlights()
	
	# Detect connections using LinkDetector
	var board = board_manager.get_board()
	var connections = LinkDetector.detect_links(board)
	
	# Apply highlights if connections found
	var has_connections = false
	for y in connections.size():
		for x in connections[y].size():
			if connections[y][x]:
				has_connections = true
				break
		if has_connections:
			break
	
	if has_connections:
		# Apply green highlights to connected tiles
		highlight_connected_tiles(connections)

func highlight_connected_tiles(connections: Array):
	# Count expected fades for batch processing
	expected_fades = 0
	faded_tiles_count = 0
	
	var board = board_manager.get_board()
	
	# Count connected tiles first
	for y in connections.size():
		for x in connections[y].size():
			if connections[y][x]:
				expected_fades += 1
	
	# If we have tiles to fade, block dragging and cancel any active drag
	if expected_fades > 0:
		var gameboard = board_manager.get_gameboard()
		if gameboard:
			gameboard.removing = true
			# Cancel any active drag
			if gameboard.drag_handler and gameboard.drag_handler.is_dragging:
				gameboard.drag_handler.cancel_drag()
	
	# Start fade animations on connected tiles
	for y in connections.size():
		for x in connections[y].size():
			if connections[y][x]:
				var tile = board[y][x] as Tile
				if tile:
					tile.highlight_connected()
					# Start fade animation on connected tiles
					tile.start_fade_animation()
					# Connect to fade completion signal (for tile replacement)
					if not tile.fade_completed.is_connected(_on_tile_fade_completed):
						tile.fade_completed.connect(_on_tile_fade_completed)

func clear_connection_highlights():
	var board = board_manager.get_board()
	for y in board_height:
		for x in board_width:
			var tile = board[y][x] as Tile
			if tile:
				tile.hide_connected_highlight()
				# Stop any ongoing fade animations
				if tile.is_fade_active():
					tile.stop_fade_animation()

func _on_tile_fade_completed(tile: Tile):
	var pos = tile.get_grid_position()
	
	# Replace tile with new random face
	tile.set_face(randi() % 10)
	tile.stop_fade_animation()  # Ensure fade is stopped and sprite restored
	
	# Update score via GameState
	if GameState:
		GameState.add_score(1)  # +1 point per removed tile
	
	# Track fade completion for batch processing
	faded_tiles_count += 1
	
	# When all fades complete, award bonus moves and check for chain reactions
	if faded_tiles_count >= expected_fades:
		await _handle_batch_completion()

func _handle_batch_completion():
	var tiles_removed = expected_fades
	faded_tiles_count = 0
	expected_fades = 0
	
	# Award bonus moves (1 move per 3 tiles removed)
	if GameState:
		var bonus_moves = tiles_removed / 3
		if bonus_moves > 0:
			GameState.moves_left += bonus_moves
			print("Bonus moves awarded: ", bonus_moves, " (total moves: ", GameState.moves_left, ")")
	
	# Re-enable dragging now that fade animations are complete
	var gameboard = board_manager.get_gameboard()
	if gameboard:
		gameboard.removing = false
	
	# Small delay before checking for chain reactions - need to be on main thread
	await Engine.get_main_loop().create_timer(0.2).timeout
	detect_and_highlight_connections()