extends Control
class_name GameBoard

# Gameboard with drag detection and row/column rotation

@export var board_width: int = 6
@export var board_height: int = 8
@export var tile_size: int = 64

# Component managers
var board_manager: BoardManager
var rotation_handler: RotationHandler
var connection_manager: ConnectionManager
var drag_handler: DragHandler
var click_audio: AudioStreamPlayer

# Convenience properties for compatibility
var board: Array:
	get:
		return board_manager.get_board() if board_manager else []
var tile_grid: Control:
	get:
		return board_manager.get_tile_grid() if board_manager else null

var removing: bool = false

# Rotation control - easily toggle rotation on/off for debugging
var rotation_enabled: bool = true

# Track drag state to clean up positions only once when drag ends
var was_dragging: bool = false


func _ready():
	# Add to gameboard group for GameState integration
	add_to_group("gameboard")
	
	# Initialize component managers
	setup_components()
	
	# Setup drag handler
	setup_drag_handler()
	
	# Connect to GameState signals
	if GameState:
		GameState.game_lost.connect(_on_game_over)
	
	# Initialize board
	initialize_board()
	
func setup_components():
	# Initialize component managers
	board_manager = BoardManager.new()
	board_manager.initialize(self, board_width, board_height, tile_size)
	
	rotation_handler = RotationHandler.new()
	rotation_handler.initialize(board_manager, board_width, board_height)
	
	connection_manager = ConnectionManager.new()
	connection_manager.initialize(board_manager, board_width, board_height)
	
	# Set connection manager reference in board manager for tile signal connections
	board_manager.set_connection_manager(connection_manager)
	
	# Set up audio system
	setup_audio()

func initialize_board():
	board_manager.clear_board()
	enable_input()
	board_manager.initialize_board()
	
	await get_tree().create_timer(0.1).timeout
	connection_manager.detect_and_highlight_connections()
	

func setup_audio():
	click_audio = AudioStreamPlayer.new()
	add_child(click_audio)
	
	var click_sound = load("res://linkage/sounds/trim_click_1.mp3")
	if click_sound:
		click_audio.stream = click_sound
		click_audio.volume_db = -12.0
		click_audio.pitch_scale = 1.0

func play_click_sound():
	if click_audio and click_audio.stream:
		click_audio.play()


func setup_drag_handler():
	drag_handler = DragHandler.new()
	add_child(drag_handler)
	drag_handler.setup(self)
	drag_handler.drag_completed.connect(_on_drag_completed)
	set_process(true)

func _on_tile_clicked(tile: Tile):
	var pos = tile.get_grid_position()
	drag_handler.start_drag(pos)
func _on_drag_completed(drag_state: Dictionary):
	if GameState and GameState.lost:
		return
	
	if GameState:
		GameState.use_move()
	
	clear_all_drag_offsets()
	connection_manager.detect_and_highlight_connections()

func _process(_delta):
	if not drag_handler:
		return
	
	var currently_dragging = drag_handler.is_dragging
	
	if currently_dragging:
		if rotation_enabled:
			var rotation_info = drag_handler.get_incremental_rotation()
			if rotation_info.get("has_increment", false):
				var increment = rotation_info.get("increment", Vector2i.ZERO)
				var drag_direction = rotation_info.get("drag_direction", Vector2.ZERO)
				var start_pos = rotation_info.get("start_pos", Vector2i.ZERO)
				
				if drag_direction.x != 0:
					rotation_handler.rotate_row(start_pos.y, increment.x)
					play_click_sound()
				elif drag_direction.y != 0:
					rotation_handler.rotate_column(start_pos.x, increment.y)
					play_click_sound()

func clear_all_drag_offsets():
	var board = board_manager.get_board()
	for y in board_height:
		for x in board_width:
			var tile = board[y][x] as Tile
			if tile:
				tile.clear_drag_offset()

func get_tile_at_position(pos: Vector2i) -> Node:
	return board_manager.get_tile_at_position(pos)
func _on_game_over():
	if drag_handler:
		drag_handler.set_process_input(false)
		drag_handler.reset_drag_state()

func disable_input():
	if drag_handler:
		drag_handler.set_process_input(false)
		drag_handler.reset_drag_state()

func enable_input():
	if drag_handler:
		drag_handler.set_process_input(true)
func enable_rotation():
	rotation_enabled = true

func disable_rotation():
	rotation_enabled = false

func toggle_rotation():
	rotation_enabled = not rotation_enabled
	return rotation_enabled

func is_rotation_enabled() -> bool:
	return rotation_enabled
