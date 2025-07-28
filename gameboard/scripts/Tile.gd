extends Control
class_name Tile

# PHASE 3: Basic Drag Mechanics  
# Tile with click detection, visual feedback, and drag indicators

@export var grid_x: int
@export var grid_y: int
@export var tile_width: int
@export var face: int  # Pipe type (0-9)

var label: Label
var color_rect: ColorRect
var is_hovered: bool = false
var border_rect: ColorRect
var drag_indicator_rect: ColorRect

# Signal for tile clicks
signal tile_clicked(tile: Tile)

# Pipe type names for display
const PIPE_NAMES = ["V↑", "V|", "V↓", "H→", "└", "┘", "H─", "┌", "┐", "H←"]

# Colors for different pipe types
const PIPE_COLORS = [
	Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW, Color.MAGENTA,
	Color.CYAN, Color.ORANGE, Color.PINK, Color.LIGHT_BLUE, Color.LIGHT_GREEN
]

func _ready():
	# Visual and input setup will be called from setup_phase1
	pass

func setup_phase1(x: int, y: int, width: int, pipe_face: int):
	grid_x = x
	grid_y = y
	tile_width = width
	face = pipe_face
	
	# Set size
	custom_minimum_size = Vector2(tile_width, tile_width)
	size = Vector2(tile_width, tile_width)
	
	# Now that we have all properties, setup visual and input
	setup_visual()
	#setup_input()
	
	#print("Tile created at (", x, ",", y, ") with face ", pipe_face)

func setup_visual():
	# Create colored background
	color_rect = ColorRect.new()
	color_rect.size = Vector2(tile_width, tile_width)
	color_rect.color = PIPE_COLORS[face % PIPE_COLORS.size()]
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(color_rect)
	
	# Create label with pipe symbol
	label = Label.new()
	label.text = PIPE_NAMES[face % PIPE_NAMES.size()]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(tile_width, tile_width)
	label.add_theme_font_size_override("font_size", 16)
	add_child(label)
	
	# Create border for hover effect
	border_rect = ColorRect.new()
	border_rect.size = Vector2(tile_width, tile_width)
	border_rect.color = Color.TRANSPARENT
	border_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(border_rect)
	border_rect.move_to_front()
	
	# Create drag indicator (red border)
	drag_indicator_rect = ColorRect.new()
	drag_indicator_rect.size = Vector2(tile_width, tile_width)
	drag_indicator_rect.color = Color.TRANSPARENT
	drag_indicator_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(drag_indicator_rect)
	drag_indicator_rect.move_to_front()
	#print("Visual setup complete for tile face ", face)

func _on_gui_input(event):
	print("Input event received on tile (", grid_x, ",", grid_y, "): ", event)
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			print("Tile clicked at (", grid_x, ",", grid_y, ") with face ", face)
			tile_clicked.emit(self)
			show_click_feedback()

func _on_mouse_entered():
	is_hovered = true
	print("Mouse entered tile (", grid_x, ",", grid_y, ")")
	show_hover_feedback()
	
func _on_mouse_exited():
	is_hovered = false
	print("Mouse exited tile (", grid_x, ",", grid_y, ")")
	hide_hover_feedback()

func show_hover_feedback():
	border_rect.color = Color.WHITE
	# Create border effect by making it slightly larger
	border_rect.position = Vector2(-2, -2)
	border_rect.size = Vector2(tile_width + 4, tile_width + 4)

func hide_hover_feedback():
	border_rect.color = Color.TRANSPARENT
	border_rect.position = Vector2.ZERO
	border_rect.size = Vector2(tile_width, tile_width)

func show_click_feedback():
	# Brief yellow flash on click
	border_rect.color = Color.YELLOW
	get_tree().create_timer(0.2).timeout.connect(func(): 
		if is_hovered:
			show_hover_feedback()
		else:
			hide_hover_feedback()
	)

# Phase 3: Drag indicator methods
func show_drag_indicator():
	drag_indicator_rect.color = Color.RED
	# Create red border effect by making it slightly larger
	drag_indicator_rect.position = Vector2(-3, -3)
	drag_indicator_rect.size = Vector2(tile_width + 6, tile_width + 6)

func hide_drag_indicator():
	drag_indicator_rect.color = Color.TRANSPARENT
	drag_indicator_rect.position = Vector2.ZERO
	drag_indicator_rect.size = Vector2(tile_width, tile_width)

func get_grid_position() -> Vector2i:
	return Vector2i(grid_x, grid_y)
