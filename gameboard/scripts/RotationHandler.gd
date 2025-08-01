extends RefCounted
class_name RotationHandler

var board_width: int
var board_height: int
var board_manager: BoardManager

func initialize(manager: BoardManager, width: int, height: int):
	board_manager = manager
	board_width = width
	board_height = height

func rotate_row(row_index: int, shift_amount: int):
	if row_index < 0 or row_index >= board_height:
		return
	
	# Normalize shift amount
	shift_amount = (board_width + (shift_amount % board_width)) % board_width
	if shift_amount == 0:
		return
	
	var board = board_manager.get_board()
	
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
	board_manager.rebuild_tile_grid()

func rotate_column(col_index: int, shift_amount: int):
	if col_index < 0 or col_index >= board_width:
		return
	
	# Normalize shift amount
	shift_amount = (board_height + (shift_amount % board_height)) % board_height
	if shift_amount == 0:
		return
	
	var board = board_manager.get_board()
	
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
	board_manager.rebuild_tile_grid()

func print_row(row_index: int):
	if row_index < 0 or row_index >= board_height:
		print("Invalid row index: ", row_index)
		return
	
	var board = board_manager.get_board()
	var row_data = []
	for x in board_width:
		var tile = board[row_index][x] as Tile
		if tile:
			row_data.append(tile.face)
		else:
			row_data.append("null")
	print("Row ", row_index, ": ", row_data)

func print_column(col_index: int):
	if col_index < 0 or col_index >= board_width:
		print("Invalid column index: ", col_index)
		return
	
	var board = board_manager.get_board()
	var col_data = []
	for y in board_height:
		var tile = board[y][col_index] as Tile
		if tile:
			col_data.append(tile.face)
		else:
			col_data.append("null")
	print("Column ", col_index, ": ", col_data)