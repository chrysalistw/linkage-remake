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
	if not drag_handler or not drag_handler.is_dragging:
		return
	
	# Clear previous indicators first
	clear_drag_indicators()
	
	var start_tile = drag_handler.start_tile_pos
	var drag_direction = drag_handler.drag_direction
	
	# Show red borders on dragged row or column based on direction
	if drag_direction.x != 0:
		highlight_row(start_tile.y, true)
	elif drag_direction.y != 0:
		highlight_column(start_tile.x, true)

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
	if not drag_handler or not drag_handler.is_dragging:
		return Vector2(col * tile_size, row * tile_size)
	
	var start_tile = drag_handler.start_tile_pos
	var grid_displacement = drag_handler.grid_displacement
	var drag_direction = drag_handler.drag_direction
	var pixel_displacement = drag_handler.pixel_displacement
	
	var final_col = col
	var final_row = row
	
	# Apply grid-based displacement with wrapping to affected tiles
	if drag_direction.x != 0 and row == start_tile.y:
		# Horizontal drag - affect entire row with wrapping
		final_col = (col + grid_displacement.x + board_width) % board_width
	elif drag_direction.y != 0 and col == start_tile.x:
		# Vertical drag - affect entire column with wrapping
		final_row = (row + grid_displacement.y + board_height) % board_height
	
	var base_pos = Vector2(final_col * tile_size, final_row * tile_size)
	
	# Add slight directional shift as visual hint during drag
	var hint_strength = 0.3  # How much of the remaining pixel displacement to show
	var hint_offset = Vector2.ZERO
	
	if drag_direction.x != 0 and row == start_tile.y:
		# Horizontal drag - show partial horizontal movement
		var remaining_pixels = pixel_displacement.x - (grid_displacement.x * tile_size)
		hint_offset.x = remaining_pixels * hint_strength
	elif drag_direction.y != 0 and col == start_tile.x:
		# Vertical drag - show partial vertical movement
		var remaining_pixels = pixel_displacement.y - (grid_displacement.y * tile_size)
		hint_offset.y = remaining_pixels * hint_strength
	
	return base_pos + hint_offset

func get_predicted_tile_position(row: int, col: int) -> Vector2i:
	if not drag_handler or not drag_handler.is_dragging:
		return Vector2i(col, row)
	
	var start_pos = drag_handler.start_tile_pos
	var grid_displacement = drag_handler.grid_displacement
	
	if drag_handler.drag_state == DragHandler.DragState.PREVIEW:
		return Vector2i(col, row)
	
	var predicted_row = row
	var predicted_col = col
	
	match drag_handler.drag_state:
		DragHandler.DragState.VERTICAL:
			if col == start_pos.x:
				var shift = grid_displacement.y
				predicted_row = (row + shift + board_height) % board_height
		DragHandler.DragState.HORIZONTAL:
			if row == start_pos.y:
				var shift = grid_displacement.x
				predicted_col = (col + shift + board_width) % board_width
	
	return Vector2i(predicted_col, predicted_row)

func get_affected_tiles() -> Array[Vector2i]:
	if not drag_handler or not drag_handler.is_dragging:
		return []
	
	var affected: Array[Vector2i] = []
	var start_tile = drag_handler.start_tile_pos
	var drag_direction = drag_handler.drag_direction
	
	# Use drag direction to determine affected tiles
	if drag_direction.x != 0:
		# Horizontal drag - entire row
		for col in range(board_width):
			affected.append(Vector2i(col, start_tile.y))
	elif drag_direction.y != 0:
		# Vertical drag - entire column
		for row in range(board_height):
			affected.append(Vector2i(start_tile.x, row))
	
	return affected

func apply_animated_positions():
	if not drag_handler or not drag_handler.is_dragging:
		return
	
	var board = board_manager.get_board()
	var affected_tiles = get_affected_tiles()
	var debug_offsets = []
	
	for tile_pos in affected_tiles:
		var tile = board[tile_pos.y][tile_pos.x] as Tile
		if tile:
			var animated_pos = get_animated_tile_position(tile_pos.y, tile_pos.x)
			var base_pos = Vector2(tile_pos.x * tile_size, tile_pos.y * tile_size)
			var offset = animated_pos - base_pos
			tile.apply_animation_offset(offset)
			
			if offset != Vector2.ZERO:
				debug_offsets.append("tile[%d,%d]:%s" % [tile_pos.x, tile_pos.y, offset])
	
	# Only print if there are significant offsets (avoid spam)
	if debug_offsets.size() > 0 and drag_handler.grid_displacement != Vector2i.ZERO:
		debug_print("Applying offsets: " + str(debug_offsets))

func reset_tile_positions():
	# Clear animation offsets from all tiles, restoring them to base positions
	print("[AnimationManager] Clearing animation offsets...")
	var board = board_manager.get_board()
	var tiles_with_offset = 0
	for y in board_height:
		for x in board_width:
			var tile = board[y][x] as Tile
			if tile:
				if tile.animation_offset != Vector2.ZERO:
					tiles_with_offset += 1
					print("  Clearing offset from tile[%d,%d]: %s" % [x, y, tile.animation_offset])
				tile.clear_animation_offset()
	print("[AnimationManager] Cleared offsets from %d tiles" % tiles_with_offset)

func draw_drag_indicators():
	if drag_handler and drag_handler.is_dragging:
		# Red outline on dragged tile
		var start_tile = drag_handler.start_tile_pos
		var from_pos = get_animated_tile_position(start_tile.y, start_tile.x)
		parent_gameboard.draw_rect(Rect2(from_pos, Vector2(tile_size, tile_size)), Color.RED, false, 4.0)

# Debug infrastructure
var debug_enabled: bool = false

func enable_debug():
	debug_enabled = true

func debug_print(message: String):
	if debug_enabled:
		print(message)
