extends RefCounted
class_name AnimationManager

var board_width: int
var board_height: int
var tile_size: int
var board_manager: BoardManager
var drag_handler: DragHandler
var parent_gameboard: GameBoard

# Efficient position caching
var animated_positions_cache: Dictionary = {}
var cache_dirty: bool = true

func initialize(gameboard: GameBoard, manager: BoardManager, width: int, height: int, size: int, handler: DragHandler):
	parent_gameboard = gameboard
	board_manager = manager
	board_width = width
	board_height = height
	tile_size = size
	drag_handler = handler

func invalidate_position_cache():
	cache_dirty = true

func get_cached_animated_position(row: int, col: int) -> Vector2:
	if cache_dirty:
		rebuild_position_cache()
	return animated_positions_cache.get(Vector2i(col, row), Vector2(col * tile_size, row * tile_size))

func rebuild_position_cache():
	animated_positions_cache.clear()
	# Only rebuild if dragging
	if drag_handler and drag_handler.is_dragging:
		var affected_tiles = get_affected_tiles()
		for tile_pos in affected_tiles:
			var animated_pos = get_animated_tile_position(tile_pos.y, tile_pos.x)
			animated_positions_cache[tile_pos] = animated_pos
	cache_dirty = false

func update_drag_indicators():
	var drag_state = drag_handler.get_drag_state()
	
	# Clear previous indicators first
	clear_drag_indicators()
	
	# Show red borders on dragged row or column
	if drag_state.state == "horizontal" and drag_state.from != Vector2i.ZERO:
		highlight_row(drag_state.from.y, true)
	elif drag_state.state == "vertical" and drag_state.from != Vector2i.ZERO:
		highlight_column(drag_state.from.x, true)

func highlight_row(row_index: int, highlight: bool):
	if row_index < 0 or row_index >= board_height:
		return
	
	var board = board_manager.get_board()
	for x in board_width:
		var tile = board[row_index][x] as Tile
		if tile:
			if highlight:
				tile.show_drag_indicator()
			else:
				tile.hide_drag_indicator()

func highlight_column(col_index: int, highlight: bool):
	if col_index < 0 or col_index >= board_width:
		return
	
	var board = board_manager.get_board()
	for y in board_height:
		var tile = board[y][col_index] as Tile
		if tile:
			if highlight:
				tile.show_drag_indicator()
			else:
				tile.hide_drag_indicator()

func clear_drag_indicators():
	var board = board_manager.get_board()
	for y in board_height:
		for x in board_width:
			var tile = board[y][x] as Tile
			if tile:
				tile.hide_drag_indicator()

func get_animated_tile_position(row: int, col: int) -> Vector2:
	var base_pos = Vector2(col * tile_size, row * tile_size)
	
	if not drag_handler or drag_handler.drag_state == DragHandler.DragState.NONE:
		return base_pos
	
	var from_tile = drag_handler.from_tile
	var displacement = drag_handler.displacement
	
	match drag_handler.drag_state:
		DragHandler.DragState.HORIZONTAL:
			if row == from_tile.y:
				base_pos.x += displacement.x
		DragHandler.DragState.VERTICAL:
			if col == from_tile.x:
				base_pos.y += displacement.y
		DragHandler.DragState.PREVIEW:
			# Show preview in detected direction - fixed logic
			if drag_handler.drag_direction.y == 0 and row == from_tile.y:
				# Horizontal movement - shift row tiles horizontally
				base_pos.x += displacement.x
			elif drag_handler.drag_direction.x == 0 and col == from_tile.x:
				# Vertical movement - shift column tiles vertically
				base_pos.y += displacement.y
	
	return base_pos

func get_predicted_tile_position(row: int, col: int) -> Vector2i:
	if not drag_handler or not drag_handler.is_dragging:
		return Vector2i(col, row)
	
	var from_pos = drag_handler.from_tile
	var to_pos = drag_handler.to_tile
	
	if not to_pos or drag_handler.drag_state == DragHandler.DragState.PREVIEW:
		return Vector2i(col, row)
	
	var predicted_row = row
	var predicted_col = col
	
	match drag_handler.drag_state:
		DragHandler.DragState.VERTICAL:
			if col == from_pos.x:
				var shift = to_pos.y - from_pos.y
				predicted_row = (row + shift + board_height) % board_height
		DragHandler.DragState.HORIZONTAL:
			if row == from_pos.y:
				var shift = to_pos.x - from_pos.x
				predicted_col = (col + shift + board_width) % board_width
	
	return Vector2i(predicted_col, predicted_row)

func get_affected_tiles() -> Array[Vector2i]:
	if not drag_handler or not drag_handler.is_dragging:
		return []
	
	var affected: Array[Vector2i] = []
	var from_tile = drag_handler.from_tile
	
	match drag_handler.drag_state:
		DragHandler.DragState.HORIZONTAL, DragHandler.DragState.PREVIEW:
			# Entire row
			for col in range(board_width):
				affected.append(Vector2i(col, from_tile.y))
		DragHandler.DragState.VERTICAL:
			# Entire column  
			for row in range(board_height):
				affected.append(Vector2i(from_tile.x, row))
	
	return affected

func apply_animated_positions():
	if not drag_handler or not drag_handler.is_dragging:
		return
	
	var board = board_manager.get_board()
	var affected_tiles = get_affected_tiles()
	for tile_pos in affected_tiles:
		var tile = board[tile_pos.y][tile_pos.x] as Tile
		if tile:
			var animated_pos = get_animated_tile_position(tile_pos.y, tile_pos.x)
			tile.position = animated_pos

func reset_tile_positions():
	board_manager.reset_tile_positions()

func draw_drag_indicators():
	if drag_handler and drag_handler.is_dragging and drag_handler.from_tile:
		# Red outline on dragged tile
		var from_pos = get_animated_tile_position(drag_handler.from_tile.y, drag_handler.from_tile.x)
		parent_gameboard.draw_rect(Rect2(from_pos, Vector2(tile_size, tile_size)), Color.RED, false, 4.0)