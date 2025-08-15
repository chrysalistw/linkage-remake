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
var fade_sprites: FadeSprites
var is_fading: bool = false
var fade_timer: Timer
var gameboard: GameBoard

# Drag offset system for click-like visual feedback
var drag_offset: Vector2 = Vector2.ZERO
var base_grid_position: Vector2 = Vector2.ZERO

# Signal for tile clicks
signal tile_clicked(tile: Tile)
# Signal for fade animation completion
signal fade_completed(tile: Tile)


func _ready():
	# Visual and input setup will be called from setup_phase1
	# Connect to tileset changes for runtime switching
	GameState.tileset_changed.connect(_on_tileset_changed)
	pass

func setup_phase1(x: int, y: int, width: int, pipe_face: int):
	grid_x = x
	grid_y = y
	tile_width = width
	face = pipe_face
	
	# Get reference to gameboard - defer to when node is ready
	call_deferred("_setup_gameboard_reference")
	
	# Set size
	custom_minimum_size = Vector2(tile_width, tile_width)
	size = Vector2(tile_width, tile_width)
	
	# Now that we have all properties, setup visual and input
	setup_visual()
	#setup_input()

func setup_visual():
	# Load pipe sprites resource based on GameState selection
	var tileset_resource = GameState.get_selected_tileset_resource()
	pipe_sprites = load(tileset_resource)
	
	# Load fade sprites resource
	fade_sprites = load("res://gameboard/resources/green_fade_sprites.tres")
	
	# Validate sprite sheets
	if pipe_sprites and not pipe_sprites.validate_sprite_sheet():
		print("Warning: Pipe sprite sheet validation failed")
	
	if fade_sprites and not fade_sprites.validate_sprite_sheet():
		print("Warning: Fade sprite sheet validation failed")
	
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
	
	# Create fade animation timer
	fade_timer = Timer.new()
	fade_timer.wait_time = 0.1  # 100ms per frame
	fade_timer.timeout.connect(_on_fade_timer_timeout)
	add_child(fade_timer)

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
	pass

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
		# During drag, show predicted face
		var display_face = get_display_face()
		var atlas_texture = pipe_sprites.get_pipe_texture(display_face)
		if atlas_texture:
			sprite.texture = atlas_texture
		else:
			print("Error: Failed to get pipe texture for face ", display_face)

# Get the face to display (predicted during drag)
func get_display_face() -> int:
	if not gameboard or not gameboard.drag_handler or not gameboard.drag_handler.is_dragging:
		return face
	
	# Get predicted grid position

	var predicted_grid = gameboard.get_predicted_tile_position(grid_y, grid_x)
	
	# If position changed, get the face that would be at this position
	if predicted_grid != Vector2i(grid_x, grid_y):
		var predicted_tile = gameboard.get_tile_at_position(predicted_grid)
		if predicted_tile:
			return predicted_tile.face
	
	return face

func get_face() -> int:
	return face

# Fade animation variables
var current_fade_frame: int = 0
var fade_frame_count: int = 5
var fade_face: int  # Store the face to use for fading (before replacement)

# Start fade animation using green_fade.png frames
func start_fade_animation():
	if is_fading:
		return  # Already fading
	
	if not fade_sprites:
		print("Warning: Fade sprites not loaded, cannot start fade animation")
		return
	
	is_fading = true
	current_fade_frame = 0
	fade_frame_count = fade_sprites.get_frame_count()
	fade_face = face  # Store current face for fade animation
	
	# Start the fade timer
	fade_timer.start()
	
	# Show first fade frame
	update_fade_frame()

# Update to the current fade frame
func update_fade_frame():
	if not is_fading or not fade_sprites:
		return
	
	# Get the fade texture for current frame using the stored fade face
	var fade_texture = fade_sprites.get_fade_texture_for_face(current_fade_frame, fade_face)
	if fade_texture and sprite:
		sprite.texture = fade_texture

# Handle fade timer timeout
func _on_fade_timer_timeout():
	if not is_fading:
		return
	
	current_fade_frame += 1
	
	if current_fade_frame >= fade_frame_count:
		# Fade animation complete
		complete_fade_animation()
	else:
		# Update to next frame
		update_fade_frame()

# Complete the fade animation and emit signal
func complete_fade_animation():
	is_fading = false
	fade_timer.stop()
	
	# Emit completion signal
	fade_completed.emit(self)

# Stop fade animation and restore normal sprite
func stop_fade_animation():
	if not is_fading:
		return
	
	is_fading = false
	fade_timer.stop()

func set_base_grid_position(pos: Vector2):
	base_grid_position = pos
	if drag_offset == Vector2.ZERO:
		position = base_grid_position

func apply_drag_offset(offset: Vector2):
	drag_offset = offset
	position = base_grid_position + drag_offset

func clear_drag_offset():
	drag_offset = Vector2.ZERO
	position = base_grid_position

# Handle tileset changes during runtime
func _on_tileset_changed(tileset_resource: String):
	# Reload sprites with new tileset
	pipe_sprites = load(tileset_resource)
	
	# Update the current sprite if it's visible
	if sprite and pipe_sprites:
		update_sprite_region()

func get_base_grid_position() -> Vector2:
	return base_grid_position
	
func is_fade_active() -> bool:
	return is_fading

func update_size(new_size: int):
	# Update tile width and resize the control
	tile_width = new_size
	custom_minimum_size = Vector2(tile_width, tile_width)
	size = Vector2(tile_width, tile_width)
func _setup_gameboard_reference():
	if not gameboard and is_inside_tree():
		gameboard = get_node_or_null("/root/Main/PlayScreen/GameBoard")
		if not gameboard:
			var tree = get_tree()
			if tree:
				var nodes_in_group = tree.get_nodes_in_group("gameboard")
				if nodes_in_group.size() > 0:
					gameboard = nodes_in_group[0]
