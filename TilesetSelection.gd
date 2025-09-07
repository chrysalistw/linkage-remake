extends Control

# Theme Selection Screen
# Allows player to choose between available theme packages (tileset + background + UI theme)

@onready var grid_container = $VBoxContainer/GridContainer
@onready var back_button = $VBoxContainer/ButtonContainer/BackButton
@onready var title_panel = $VBoxContainer/TitlePanel
@onready var background = $Background

var theme_buttons: Array[Button] = []
var theme_previews: Array = []  # Now holds Array[TextureRect] for each theme
var background_previews: Array[ColorRect] = []
var selection_frames: Array[Panel] = []

func _ready():
	setup_theme_buttons()
	setup_previews()
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Apply current theme
	_apply_current_theme()
	_connect_theme_signals()
	
	# Setup responsive design and hover effects
	setup_hover_effects()
	_optimize_for_mobile()
	var button = $VBoxContainer/GridContainer/TilesetButton4

func setup_theme_buttons():
	# Get theme buttons and connect signals
	for i in range(6):  # 6 total slots (3 active + 3 future)
		var button_name = "TilesetButton" + str(i)
		var button = grid_container.get_node(button_name)
		if button:
			theme_buttons.append(button)
			
			# Create selection frame for each button
			var frame = Panel.new()
			frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
			frame.visible = false  # Initially hidden
			frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			frame.position = Vector2(0, 0)  # Same position as button
			frame.size = button.size  # Same size as button
			
			# Create frame style
			var frame_style = StyleBoxFlat.new()
			frame_style.bg_color = Color.TRANSPARENT  # No background fill
			frame_style.corner_radius_top_left = 12
			frame_style.corner_radius_top_right = 12
			frame_style.corner_radius_bottom_left = 12
			frame_style.corner_radius_bottom_right = 12
			frame_style.border_width_left = 4
			frame_style.border_width_top = 4
			frame_style.border_width_right = 4
			frame_style.border_width_bottom = 4
			frame_style.border_color = Color.WHITE  # Default frame color
			frame.add_theme_stylebox_override("panel", frame_style)
			
			button.add_child(frame)
			button.move_child(frame, 0)  # Move frame to first child (behind content)
			selection_frames.append(frame)
			
			if i < GameState.get_theme_count():
				# Active theme
				button.pressed.connect(_on_theme_button_pressed.bind(i))
				# Update button text with theme name
				button.text = GameState.get_theme_name(i)
			else:
				# Future slot - keep disabled
				button.text = "Coming Soon"
				button.disabled = true
	
	# Apply initial selection frame after all buttons are set up
	update_selection_frame()

func setup_previews():
	# Setup preview textures and background colors for available themes
	for i in range(3):  # Only for active themes
		if i >= theme_buttons.size():
			continue
			
		var button = theme_buttons[i]
		if i < GameState.get_theme_count():
			var theme_data = GameState.available_themes[i]
			print("TilesetSelection: Loading theme ", i, ": ", theme_data.get("name", "Unknown"))
			print("TilesetSelection: Tileset path: ", theme_data.get("tileset_path", "Missing"))
			
			# Create enhanced preview grid instead of single texture
			create_enhanced_preview_grid(button, i, theme_data)
			
			# Setup background color preview (if there's a ColorRect for it)
			var bg_preview_name = "BackgroundPreview" + str(i)
			var bg_preview = button.get_node_or_null(bg_preview_name) as ColorRect
			if bg_preview:
				background_previews.append(bg_preview)
				bg_preview.color = theme_data["background_color"]

func create_enhanced_preview_grid(button: Button, theme_index: int, theme_data: Dictionary):
	"""Create a 2x2 grid of different pipe tiles to show tileset variety"""
	
	# Remove existing single preview if it exists
	var old_preview_name = "TilesetPreview" + str(theme_index)
	var old_preview = button.get_node_or_null(old_preview_name)
	if old_preview:
		old_preview.queue_free()
	
	# Load the tileset
	var tile_sprites = load(theme_data["tileset_path"]) as UnifiedTileSprites
	if not tile_sprites:
		print("TilesetSelection: Failed to load unified tile sprites from: ", theme_data["tileset_path"])
		return
	
	# Create container for the preview grid
	var preview_container = Control.new()
	preview_container.name = "EnhancedPreview" + str(theme_index)
	preview_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	preview_container.position = Vector2(-60, -60)  # Larger preview area
	preview_container.size = Vector2(120, 120)
	preview_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(preview_container)
	
	# Create background panel for the preview
	var preview_bg = Panel.new()
	preview_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Style the background panel with theme colors
	var bg_style = StyleBoxFlat.new()
	var bg_color = theme_data.get("background_color", Color.WHITE)
	if bg_color is String:
		bg_color = Color(bg_color)
	bg_style.bg_color = Color(bg_color.r * 0.9, bg_color.g * 0.9, bg_color.b * 0.9, 0.8)
	bg_style.corner_radius_top_left = 8
	bg_style.corner_radius_top_right = 8
	bg_style.corner_radius_bottom_left = 8
	bg_style.corner_radius_bottom_right = 8
	bg_style.border_width_left = 2
	bg_style.border_width_top = 2
	bg_style.border_width_right = 2
	bg_style.border_width_bottom = 2
	bg_style.border_color = Color(bg_color.r * 0.7, bg_color.g * 0.7, bg_color.b * 0.7, 1.0)
	preview_bg.add_theme_stylebox_override("panel", bg_style)
	preview_container.add_child(preview_bg)
	
	# Create 2x2 grid of different pipe tiles
	var grid_container = GridContainer.new()
	grid_container.columns = 2
	grid_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grid_container.position = Vector2(-48, -48)
	grid_container.size = Vector2(96, 96)
	grid_container.add_theme_constant_override("h_separation", 4)
	grid_container.add_theme_constant_override("v_separation", 4)
	grid_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_container.add_child(grid_container)
	
	# Show 4 different pipe types to demonstrate variety
	var preview_faces = [0, 3, 5, 9]  # Different pipe connections for visual variety
	var preview_tiles = []
	
	for j in range(4):
		var tile_rect = TextureRect.new()
		tile_rect.custom_minimum_size = Vector2(44, 44)
		tile_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tile_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var face_index = preview_faces[j] if j < preview_faces.size() else 0
		var texture = tile_sprites.get_pipe_texture(face_index)
		if texture:
			tile_rect.texture = texture
		
		grid_container.add_child(tile_rect)
		preview_tiles.append(tile_rect)
	
	# Store references for animation
	theme_previews.append(preview_tiles)
	
	# Start animation cycle for this preview
	start_preview_animation(theme_index, tile_sprites, preview_tiles)

func start_preview_animation(theme_index: int, tile_sprites: UnifiedTileSprites, preview_tiles: Array):
	"""Start animated cycling through different tile faces"""
	var animation_timer = Timer.new()
	animation_timer.wait_time = 2.0  # Change tiles every 2 seconds
	animation_timer.timeout.connect(_on_preview_animation_timeout.bind(theme_index, tile_sprites, preview_tiles))
	add_child(animation_timer)
	animation_timer.start()

var animation_face_offset = 0

func _on_preview_animation_timeout(theme_index: int, tile_sprites: UnifiedTileSprites, preview_tiles: Array):
	"""Cycle through different tile faces for animation"""
	animation_face_offset += 1
	var base_faces = [0, 3, 5, 9]
	
	for i in range(preview_tiles.size()):
		if i < base_faces.size():
			var face_index = (base_faces[i] + animation_face_offset) % 16  # Cycle through 16 different faces
			var texture = tile_sprites.get_pipe_texture(face_index)
			if texture:
				preview_tiles[i].texture = texture

func _on_theme_button_pressed(index: int):
	# Update theme selection in GameState
	GameState.set_selected_theme(index)
	
	# Update visual feedback
	update_selection_frame()
	
	# Optional: Play sound effect
	GameState.play_sound("click")

func update_selection_frame():
	# Reset all frames and apply selection frame to active theme
	for i in range(selection_frames.size()):
		if i < GameState.get_theme_count() and i < selection_frames.size():
			if i == GameState.selected_theme_index:
				# Selected theme - show frame with theme accent color
				show_selection_frame(i)
			else:
				# Unselected theme - hide frame
				hide_selection_frame(i)

func show_selection_frame(theme_index: int):
	"""Show the selection frame for the selected theme"""
	if theme_index < selection_frames.size() and theme_index < theme_buttons.size():
		var frame = selection_frames[theme_index]
		var button = theme_buttons[theme_index]
		var theme_data = GameState.available_themes[theme_index]
		var accent_color = _get_theme_accent_color(theme_data)
		
		# Resize frame to match current button size
		frame.size = button.size
		frame.position = Vector2(0, 0)
		
		# Update frame style with theme accent color
		var frame_style = frame.get_theme_stylebox("panel") as StyleBoxFlat
		if frame_style:
			frame_style.border_color = accent_color
		
		# Make frame visible
		frame.visible = true
		
		# Add subtle pulsing animation to the frame
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(frame, "modulate", Color(1.0, 1.0, 1.0, 0.7), 0.8)
		tween.tween_property(frame, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.8)

func hide_selection_frame(theme_index: int):
	"""Hide the selection frame for unselected themes"""
	if theme_index < selection_frames.size():
		var frame = selection_frames[theme_index]
		frame.visible = false

func _get_theme_accent_color(theme_data: Dictionary) -> Color:
	# Return accent color based on theme name
	var theme_name = theme_data.get("name", "")
	if "Green" in theme_name:
		return Color(0.2, 1.0, 0.2, 0.8)  # Bright green border
	elif "Red" in theme_name:
		return Color(1.0, 0.2, 0.2, 0.8)  # Bright red border
	elif "Blue" in theme_name:
		return Color(0.2, 0.5, 1.0, 0.8)  # Bright blue border
	else:
		return Color(1.0, 1.0, 0.2, 0.8)  # Default yellow border

func _on_back_button_pressed():
	# Return to title screen
	GameState.play_sound("click")
	get_tree().change_scene_to_file("res://TitleScreen.tscn")

func _connect_theme_signals():
	# Connect to theme change signal
	GameState.theme_changed.connect(_on_theme_changed)

func _on_theme_changed(theme_data: Dictionary):
	_apply_theme(theme_data)
	# Also update selection frame
	update_selection_frame()

func _apply_current_theme():
	var theme_data = GameState.get_selected_theme_data()
	_apply_theme(theme_data)

func _apply_theme(theme_data: Dictionary):
	# Apply background color
	if background and theme_data.has("background_color"):
		var bg_color = theme_data["background_color"]
		if bg_color is String:
			background.color = Color(bg_color)
		else:
			background.color = bg_color
	
	# Apply theme resource
	if theme_data.has("theme_path"):
		var theme_resource = load(theme_data["theme_path"]) 
		if theme_resource:
			theme = theme_resource
	
	# Apply theme's panel style to title panel
	if title_panel and theme_data.has("theme_path"):
		var theme_resource = load(theme_data["theme_path"])
		if theme_resource:
			title_panel.theme = theme_resource

func setup_hover_effects():
	"""Add hover effects to theme buttons for better interactivity"""
	for i in range(theme_buttons.size()):
		if i < GameState.get_theme_count():
			var button = theme_buttons[i]
			button.mouse_entered.connect(_on_theme_button_hover_enter.bind(i))
			button.mouse_exited.connect(_on_theme_button_hover_exit.bind(i))

func _on_theme_button_hover_enter(theme_index: int):
	"""Handle mouse hover enter for theme buttons"""
	if theme_index != GameState.selected_theme_index:
		var button = theme_buttons[theme_index]
		# Subtle hover effect for unselected themes
		var tween = create_tween()
		tween.tween_property(button, "modulate", Color(1.1, 1.1, 1.05), 0.2)

func _on_theme_button_hover_exit(theme_index: int):
	"""Handle mouse hover exit for theme buttons"""
	if theme_index != GameState.selected_theme_index:
		var button = theme_buttons[theme_index]
		# Return to normal state
		var tween = create_tween()
		tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0), 0.2)

func _optimize_for_mobile():
	"""Optimize layout and sizing for mobile devices"""
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Adjust grid layout for smaller screens
	if viewport_size.x < 800:  # Mobile portrait
		grid_container.columns = 2
		# Reduce button size for smaller screens
		for button in theme_buttons:
			button.custom_minimum_size = Vector2(160, 200)
		
		# Reduce spacing
		grid_container.add_theme_constant_override("h_separation", 25)
		grid_container.add_theme_constant_override("v_separation", 25)
	elif viewport_size.x < 1200:  # Mobile landscape / tablet
		grid_container.columns = 3
		# Slightly smaller buttons
		for button in theme_buttons:
			button.custom_minimum_size = Vector2(180, 220)
		
		# Standard spacing
		grid_container.add_theme_constant_override("h_separation", 35)
		grid_container.add_theme_constant_override("v_separation", 35)
	else:  # Desktop
		grid_container.columns = 3
		# Full-size buttons as defined in scene
		for button in theme_buttons:
			button.custom_minimum_size = Vector2(200, 240)
		
		# Larger spacing for desktop
		grid_container.add_theme_constant_override("h_separation", 40)
		grid_container.add_theme_constant_override("v_separation", 40)
