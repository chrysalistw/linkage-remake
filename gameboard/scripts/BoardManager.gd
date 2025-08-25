extends RefCounted
class_name BoardManager

var board: Array = []
var board_width: int
var board_height: int
var tile_size: int
var tile_scene: PackedScene
var tile_grid: Control
var parent_gameboard: GameBoard
var connection_manager: ConnectionManager

func initialize(gameboard: GameBoard, width: int, height: int, size: int):
	parent_gameboard = gameboard
	board_width = width
	board_height = height
	tile_size = size
	tile_scene = preload("res://gameboard/scenes/Tile.tscn")
	setup_tile_grid()

func setup_tile_grid():
	tile_grid = Control.new()
	tile_grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent_gameboard.add_child(tile_grid)

func initialize_board():
	clear_board()
	
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
	

func create_tile(x: int, y: int):
	var tile_instance = tile_scene.instantiate()
	tile_instance.setup_phase1(x, y, tile_size, randi() % 10)
	
	# Connect tile click signal to parent
	tile_instance.tile_clicked.connect(parent_gameboard._on_tile_clicked)
	
	# Connect fade completion signal to connection manager
	if connection_manager:
		tile_instance.fade_completed.connect(connection_manager._on_tile_fade_completed)
	
	# Store in board array
	board[y][x] = tile_instance
	
	# Add to grid and set initial position
	tile_grid.add_child(tile_instance)
	var base_pos = Vector2(x * tile_size, y * tile_size)
	tile_instance.set_base_grid_position(base_pos)
	
	return tile_instance

func clear_board():
	if tile_grid:
		for child in tile_grid.get_children():
			child.queue_free()
	board.clear()

func get_tile_at_position(pos: Vector2i) -> Node:
	if pos.x >= 0 and pos.x < board_width and pos.y >= 0 and pos.y < board_height:
		return board[pos.y][pos.x]
	return null

func rebuild_tile_grid():
	# Clear current grid children
	for child in tile_grid.get_children():
		tile_grid.remove_child(child)
	
	# Re-add tiles in correct row-major order with proper positions
	for y in board_height:
		for x in board_width:
			var tile = board[y][x]
			if tile:
				tile_grid.add_child(tile)
				var base_pos = Vector2(x * tile_size, y * tile_size)
				tile.set_base_grid_position(base_pos)
	
	# Debug: Print board after rebuild
	debug_print_board()
	

func reset_tile_positions():
	# Reset all tiles to their grid positions
	for y in board_height:
		for x in board_width:
			var tile = board[y][x] as Tile
			if tile:
				var base_pos = Vector2(x * tile_size, y * tile_size)
				tile.set_base_grid_position(base_pos)
				tile.clear_drag_offset()

func get_board() -> Array:
	return board

func get_tile_grid() -> Control:
	return tile_grid

func set_connection_manager(manager: ConnectionManager):
	connection_manager = manager

# Debug function to print all tile faces on the board
func debug_print_board():
	print("=== BOARD TILE FACES DEBUG ===")
	for y in board_height:
		var row_string = ""
		for x in board_width:
			var tile = board[y][x] 
			if tile and tile.has_method("get_face"):
				row_string += str(tile.get_face()).pad_zeros(2) + " "
			else:
				row_string += "-- "
		print("Row %d: %s" % [y, row_string])
	print("===============================")

func get_gameboard() -> GameBoard:
	return parent_gameboard

func update_tile_sizes_and_positions():
	# Update all existing tiles with new tile_size and positions
	for y in board_height:
		for x in board_width:
			var tile = board[y][x] as Tile
			if tile:
				# Update tile size
				tile.update_size(tile_size)
				# Update position
				var base_pos = Vector2(x * tile_size, y * tile_size)
				tile.set_base_grid_position(base_pos)
