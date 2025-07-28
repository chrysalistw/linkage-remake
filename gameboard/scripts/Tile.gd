extends Control
class_name Tile

# Tile with click detection, visual feedback, and drag indicators

@export var grid_x: int
@export var grid_y: int
@export var tile_width: int
@export var face: int  # Pipe type (0-9)

var sprite: TextureRect
var is_hovered: bool = false
var border_rect: ColorRect
var drag_indicator_rect: ColorRect
var connection_indicator_rect: ColorRect
var pipe_sprites: PipeSprites

# Signal for tile clicks
signal tile_clicked(tile: Tile)

# Pipe face names for debugging
const PIPE_NAMES = ["V↑", "V|", "V↓", "H→", "└", "┘", "H─", "┌", "┐", "H←"]

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

func setup_visual():
	# Load pipe sprites resource
	pipe_sprites = load("res://gameboard/resources/pipe_sprites.tres")
	
	# Validate sprite sheet
	if pipe_sprites and not pipe_sprites.validate_sprite_sheet():
		print("Warning: Pipe sprite sheet validation failed")
	
	# Create sprite display
	sprite = TextureRect.new()
	sprite.size = Vector2(tile_width, tile_width)
	sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Set up the texture for the specific face
	update_sprite_region()
	
	add_child(sprite)
	
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
	
	# Create connection indicator (green background) - add it first so it's behind
	connection_indicator_rect = ColorRect.new()
	connection_indicator_rect.size = Vector2(tile_width, tile_width)
	connection_indicator_rect.color = Color.TRANSPARENT
	connection_indicator_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Add connection indicator first, then move sprite to front
	add_child(connection_indicator_rect)
	sprite.move_to_front()

func _on_gui_input(event):
	if event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			tile_clicked.emit(self)
			show_click_feedback()

func _on_mouse_entered():
	is_hovered = true
	show_hover_feedback()
	
func _on_mouse_exited():
	is_hovered = false
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

# Drag indicator methods
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

# Connection highlighting methods
func highlight_connected():
	# Add green tint to sprite
	sprite.modulate = Color(0.8, 1.2, 0.8, 1.0)  # Green tint
	connection_indicator_rect.color = Color.GREEN
	connection_indicator_rect.color.a = 0.4  # Semi-transparent

func hide_connected_highlight():
	sprite.modulate = Color.WHITE  # Reset to normal
	connection_indicator_rect.color = Color.TRANSPARENT

# Set face method for tile replacement
func set_face(new_face: int):
	face = new_face
	# Update sprite region
	update_sprite_region()

# Update the texture region to show the correct pipe face
func update_sprite_region():
	if sprite and pipe_sprites:
		var atlas_texture = pipe_sprites.get_pipe_texture(face)
		if atlas_texture:
			sprite.texture = atlas_texture
		else:
			print("Error: Failed to get pipe texture for face ", face)

func get_face() -> int:
	return face
