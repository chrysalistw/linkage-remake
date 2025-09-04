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
var unified_sprites: UnifiedTileSprites
var is_fading: bool = false
var fade_timer: Timer  # Keep for backward compatibility
var gameboard: GameBoard
var animation_controller: UnifiedTileSprites.TileAnimationController

# Drag offset system for click-like visual feedback
var drag_offset: Vector2 = Vector2.ZERO
var base_grid_position: Vector2 = Vector2.ZERO

# Signal for tile clicks
signal tile_clicked(tile: Tile)
# Signal for fade animation completion
signal fade_completed(tile: Tile)


func _ready():
	# Visual and input setup will be called from setup_phase1
	# Connect to theme changes for runtime switching
	GameState.theme_changed.connect(_on_theme_changed)
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
	# Load unified sprites resource based on GameState selection
	var tileset_resource = GameState.get_selected_tileset_resource()
	unified_sprites = load(tileset_resource)
	
	# Validate unified sprite sheet
	if unified_sprites and not unified_sprites.validate_unified_sheet():
		print("Warning: Unified sprite sheet validation failed")
	
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
	if sprite and unified_sprites:
		# During drag, show predicted face
		var display_face = get_display_face()
		var atlas_texture = unified_sprites.get_pipe_texture(display_face)
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

# Legacy fade animation variables (kept for backward compatibility)
var current_fade_frame: int = 0
var fade_frame_count: int = 5
var fade_face: int  # Store the face to use for fading (before replacement)

# Modern animation system preference
@export var use_modern_animation: bool = true

# Start fade animation - now uses modern animation system by default
func start_fade_animation():
	if is_fading:
		return  # Already fading
	
	if not unified_sprites:
		print("Warning: Unified sprites not loaded, cannot start fade animation")
		return
	
	is_fading = true
	fade_face = face  # Store current face for fade animation
	
	if use_modern_animation:
		_start_modern_fade_animation()
	else:
		_start_legacy_fade_animation()

# Modern fade animation using AnimationController
func _start_modern_fade_animation():
	# Create animation controller if not exists
	if not animation_controller:
		animation_controller = unified_sprites.create_animation_controller(fade_face)
		if animation_controller:
			add_child(animation_controller)
			animation_controller.animation_finished.connect(_on_modern_animation_finished)
	
	if animation_controller:
		# Position and center the animation controller properly
		animation_controller.position = Vector2(tile_width / 2.0, tile_width / 2.0)
		# Scale to match tile size (animation sprites are 64x64 base size)
		var scale_factor = tile_width / 64.0
		animation_controller.scale = Vector2(scale_factor, scale_factor)
		
		# Hide the static sprite and show the animated one
		sprite.visible = false
		animation_controller.play_animation()

# Legacy fade animation using timer system
func _start_legacy_fade_animation():
	current_fade_frame = 0
	fade_frame_count = unified_sprites.get_frame_count()
	
	# Start the fade timer
	fade_timer.start()
	
	# Show first fade frame
	update_fade_frame()

# Update to the current fade frame
func update_fade_frame():
	if not is_fading or not unified_sprites:
		return
	
	# Get the fade texture for current frame using the stored fade face
	var fade_texture = unified_sprites.get_fade_texture_for_face(current_fade_frame, fade_face)
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
	
	if use_modern_animation and animation_controller:
		animation_controller.stop_animation()
		animation_controller.queue_free()
		animation_controller = null
		sprite.visible = true  # Restore static sprite visibility
	else:
		fade_timer.stop()
	
	# Emit completion signal
	fade_completed.emit(self)

# Modern animation finished callback
func _on_modern_animation_finished():
	complete_fade_animation()

# Stop fade animation and restore normal sprite
func stop_fade_animation():
	if not is_fading:
		return
	
	is_fading = false
	
	if use_modern_animation and animation_controller:
		animation_controller.stop_animation()
		animation_controller.queue_free()
		animation_controller = null
		sprite.visible = true  # Restore static sprite visibility
	else:
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
func _on_theme_changed(theme_data: Dictionary):
	# Reload sprites with new tileset from theme
	var tileset_resource = theme_data["tileset_resource"]
	unified_sprites = load(tileset_resource)
	
	# Update the current sprite if it's visible
	if sprite and unified_sprites:
		update_sprite_region()

func get_base_grid_position() -> Vector2:
	return base_grid_position
	
func is_fade_active() -> bool:
	return is_fading

# Get animation progress (0.0 to 1.0) for modern animations
func get_animation_progress() -> float:
	if use_modern_animation and animation_controller:
		return animation_controller.get_animation_progress()
	elif not use_modern_animation and is_fading:
		# Legacy progress calculation
		var progress = float(current_fade_frame) / float(fade_frame_count - 1)
		return clamp(progress, 0.0, 1.0)
	else:
		return 0.0

# Pause/resume animation (only available with modern system)
func pause_animation():
	if use_modern_animation and animation_controller:
		animation_controller.pause_animation()

func resume_animation():
	if use_modern_animation and animation_controller:
		animation_controller.resume_animation()

# Restart animation
func restart_animation():
	if use_modern_animation and animation_controller:
		animation_controller.restart_animation()
	else:
		stop_fade_animation()
		start_fade_animation()

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

# Simple wrapper for reward button functionality
func start_fade_out():
	"""Start fade out animation for tile replacement"""
	start_fade_animation()
