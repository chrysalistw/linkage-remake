extends Control
class_name GameBoard

# PHASE 2: Input Detection
# Gameboard with click detection and tile interaction

@export var board_width: int = 6
@export var board_height: int = 8
@export var tile_size: int = 64

var board: Array = []
var tile_scene: PackedScene
var tile_grid: GridContainer

func _ready():
	# Create tile grid container
	setup_tile_grid()
	
	# Load tile scene
	tile_scene = preload("res://gameboard/scenes/Tile.tscn")
	
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

# Phase 2: Handle tile clicks
func _on_tile_clicked(tile: Tile):
	var pos = tile.get_grid_position()
	print("GameBoard: Tile clicked at (", pos.x, ",", pos.y, ") with face ", tile.face)
	# Future: Add drag detection here

func get_tile_at_position(pos: Vector2i) -> Node:
	if pos.x >= 0 and pos.x < board_width and pos.y >= 0 and pos.y < board_height:
		return board[pos.y][pos.x]
	return null
