extends Control
class_name GameBoard

# Gameboard with drag detection and row/column rotation

@export var board_width: int = 6
@export var board_height: int = 8
@export var tile_size: int = 64

var board: Array = []
var tile_scene: PackedScene
var tile_grid: GridContainer
var drag_handler: DragHandler
var removing: bool = false

func _ready():
	# Add to gameboard group for GameState integration
	add_to_group("gameboard")
	
	# Create tile grid container
	setup_tile_grid()
	
	# Load tile scene
	tile_scene = preload("res://gameboard/scenes/Tile.tscn")
	
	# Setup drag handler
	setup_drag_handler()
	
	# Connect to GameState signals
	if GameState:
		GameState.game_lost.connect(_on_game_over)
	
	# Initialize board
	initialize_board()
	
func setup_tile_grid():
	tile_grid = GridContainer.new()
	tile_grid.columns = board_width
	tile_grid.add_theme_constant_override("h_separation", 0)
	tile_grid.add_theme_constant_override("v_separation", 0)
	add_child(tile_grid)

func initialize_board():
	# Clear existing board
	clear_board()
	
	# Re-enable input (fixes restart bug)
	enable_input()
	
	# Create 2D array for tile data
	board = []
	for y in board_height:
		var row = []
		for x in board_width:
			row.append(null)
		board.append(row)
	
	# Create and place tiles
	for y in board_height:
		for x in board_width:
			create_tile(x, y)
	
	# Initial connection detection
	await get_tree().create_timer(0.1).timeout  # Give tiles time to initialize
	detect_and_highlight_connections()

func create_tile(x: int, y: int):
	var tile_instance = tile_scene.instantiate()
	tile_instance.setup_phase1(x, y, tile_size, randi() % 10)  # Random face 0-9
	
	# Connect tile click signal
	tile_instance.tile_clicked.connect(_on_tile_clicked)
	
	# Store in board array
	board[y][x] = tile_instance
	
	# Add to grid
	tile_grid.add_child(tile_instance)
	
	return tile_instance

func clear_board():
	if tile_grid:
		for child in tile_grid.get_children():
			child.queue_free()
	board.clear()

func setup_drag_handler():
	drag_handler = DragHandler.new()
	add_child(drag_handler)
	drag_handler.setup(self)
	drag_handler.drag_completed.connect(_on_drag_completed)
	
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
	clear_drag_indicators()
	
	if drag_state.state == "horizontal":
		rotate_row(drag_state.from.y, drag_state.to.x - drag_state.from.x)
	elif drag_state.state == "vertical":
		rotate_column(drag_state.from.x, drag_state.to.y - drag_state.from.y)
	
	# Use one move per drag operation
	if GameState:
		GameState.use_move()
		print("Move used, moves left: ", GameState.moves_left)
	
	# Detect connections after move
	detect_and_highlight_connections()

# Row rotation logic
func rotate_row(row_index: int, shift_amount: int):
	if row_index < 0 or row_index >= board_height:
		return
	
	# Normalize shift amount
	shift_amount = shift_amount % board_width
	if shift_amount == 0:
		return
	
	
	# Get current row data
	var old_row = []
	for x in board_width:
		old_row.append(board[row_index][x])
	
	# Apply rotation
	for x in board_width:
		var new_x = (x + shift_amount + board_width) % board_width
		board[row_index][new_x] = old_row[x]
		
		# Update tile grid position
		var tile = old_row[x] as Tile
		if tile:
			tile.grid_x = new_x
	
	# Rebuild tile grid to reflect new positions
	rebuild_tile_grid()

# Column rotation logic
func rotate_column(col_index: int, shift_amount: int):
	if col_index < 0 or col_index >= board_width:
		return
	
	# Normalize shift amount
	shift_amount = shift_amount % board_height
	if shift_amount == 0:
		return
	
	
	# Get current column data
	var old_column = []
	for y in board_height:
		old_column.append(board[y][col_index])
	
	# Apply rotation
	for y in board_height:
		var new_y = (y + shift_amount + board_height) % board_height
		board[new_y][col_index] = old_column[y]
		
		# Update tile grid position
		var tile = old_column[y] as Tile
		if tile:
			tile.grid_y = new_y
	
	# Rebuild tile grid to reflect new positions
	rebuild_tile_grid()

# Rebuild the tile grid in correct order after rotation
func rebuild_tile_grid():
	# Clear current grid children
	for child in tile_grid.get_children():
		tile_grid.remove_child(child)
	
	# Re-add tiles in correct row-major order
	for y in board_height:
		for x in board_width:
			var tile = board[y][x]
			if tile:
				tile_grid.add_child(tile)

# Process function to update drag visual indicators
func _process(_delta):
	if drag_handler and drag_handler.dragging:
		update_drag_indicators()

# Update visual indicators during drag
func update_drag_indicators():
	var drag_state = drag_handler.get_drag_state()
	
	# Clear previous indicators first
	clear_drag_indicators()
	
	# Show red borders on dragged row or column
	if drag_state.state == "horizontal" and drag_state.from != Vector2i.ZERO:
		highlight_row(drag_state.from.y, true)
	elif drag_state.state == "vertical" and drag_state.from != Vector2i.ZERO:
		highlight_column(drag_state.from.x, true)

# Highlight all tiles in a row with red border
func highlight_row(row_index: int, highlight: bool):
	if row_index < 0 or row_index >= board_height:
		return
		
	for x in board_width:
		var tile = board[row_index][x] as Tile
		if tile:
			if highlight:
				tile.show_drag_indicator()
			else:
				tile.hide_drag_indicator()

# Highlight all tiles in a column with red border  
func highlight_column(col_index: int, highlight: bool):
	if col_index < 0 or col_index >= board_width:
		return
		
	for y in board_height:
		var tile = board[y][col_index] as Tile
		if tile:
			if highlight:
				tile.show_drag_indicator()
			else:
				tile.hide_drag_indicator()

# Clear all drag visual indicators
func clear_drag_indicators():
	for y in board_height:
		for x in board_width:
			var tile = board[y][x] as Tile
			if tile:
				tile.hide_drag_indicator()

func get_tile_at_position(pos: Vector2i) -> Node:
	if pos.x >= 0 and pos.x < board_width and pos.y >= 0 and pos.y < board_height:
		return board[pos.y][pos.x]
	return null

# Connection detection and highlighting
func detect_and_highlight_connections():
	# Clear previous connection highlights
	clear_connection_highlights()
	
	# Detect connections using LinkDetector
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
		# Force a visual update
		await get_tree().process_frame

# Apply green highlights to connected tiles and start fade animations
func highlight_connected_tiles(connections: Array):
	# Count expected fades for batch processing
	expected_fades = 0
	faded_tiles_count = 0
	
	# Count connected tiles first
	for y in connections.size():
		for x in connections[y].size():
			if connections[y][x]:
				expected_fades += 1
	
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

# Clear all connection highlights and stop fade animations
func clear_connection_highlights():
	for y in board_height:
		for x in board_width:
			var tile = board[y][x] as Tile
			if tile:
				tile.hide_connected_highlight()
				# Stop any ongoing fade animations
				if tile.is_fade_active():
					tile.stop_fade_animation()

# Track completed fades for batch processing
var faded_tiles_count: int = 0
var expected_fades: int = 0

# Handle tile fade completion - replace tile and update score
func _on_tile_fade_completed(tile: Tile):
	var pos = tile.get_grid_position()
	print("Tile fade completed at position: ", pos)
	
	# Replace tile with new random face
	tile.set_face(randi() % 10)
	tile.stop_fade_animation()  # Ensure fade is stopped and sprite restored
	
	# Update score via GameState
	if GameState:
		GameState.add_score(1)  # +1 point per removed tile
		print("Score increased by 1, new score: ", GameState.score)
	
	# Track fade completion for batch processing
	faded_tiles_count += 1
	
	# When all fades complete, award bonus moves and check for chain reactions
	if faded_tiles_count >= expected_fades:
		var tiles_removed = expected_fades
		faded_tiles_count = 0
		expected_fades = 0
		
		# Award bonus moves (1 move per 3 tiles removed)
		if GameState:
			var bonus_moves = tiles_removed / 3
			if bonus_moves > 0:
				GameState.moves_left += bonus_moves
				print("Bonus moves awarded: ", bonus_moves, " (total moves: ", GameState.moves_left, ")")
		
		# Small delay before checking for chain reactions
		await get_tree().create_timer(0.2).timeout
		detect_and_highlight_connections()

# Handle game over - disable input
func _on_game_over():
	print("Game Over! No more moves left.")
	# Disable drag handler to prevent further moves
	if drag_handler:
		drag_handler.set_process_input(false)
		drag_handler.dragging = false

# Allow moves again (for restart functionality)
func enable_input():
	if drag_handler:
		drag_handler.set_process_input(true)
