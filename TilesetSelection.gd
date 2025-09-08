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
	
	# Preload interstitial ad for theme change
	AdMobManager.load_interstitial()
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
				# Remove theme name text - keep button empty for visual preview focus
				button.text = ""
			else:
				# Future slot - keep disabled
				button.text = "Coming Soon"
				button.disabled = true
	
	# Apply initial selection frame after all buttons are set up
	update_selection_frame()

func apply_theme_to_button(button: Button, theme_index: int, theme_data: Dictionary):
	"""Apply the theme's visual styling to its button"""
	
	# Load the theme resource if available
	if theme_data.has("theme_path"):
		var theme_resource = load(theme_data["theme_path"])
		if theme_resource:
			button.theme = theme_resource
	
	# Create a custom StyleBox for the button background using theme colors
	var bg_color = theme_data.get("background_color", Color.WHITE)
	if bg_color is String:
		bg_color = Color(bg_color)
	
	# Create StyleBoxFlat for normal state
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(bg_color.r * 0.95, bg_color.g * 0.95, bg_color.b * 0.95, 1.0)  # Slightly darker than background
	normal_style.corner_radius_top_left = 12
	normal_style.corner_radius_top_right = 12
	normal_style.corner_radius_bottom_left = 12
	normal_style.corner_radius_bottom_right = 12
	normal_style.border_width_left = 3
	normal_style.border_width_top = 3
	normal_style.border_width_right = 3
	normal_style.border_width_bottom = 3
	normal_style.border_color = Color(bg_color.r * 0.7, bg_color.g * 0.7, bg_color.b * 0.7, 1.0)
	
	# Create StyleBoxFlat for hover state
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(bg_color.r * 1.05, bg_color.g * 1.05, bg_color.b * 1.05, 1.0)  # Slightly brighter
	hover_style.corner_radius_top_left = 12
	hover_style.corner_radius_top_right = 12
	hover_style.corner_radius_bottom_left = 12
	hover_style.corner_radius_bottom_right = 12
	hover_style.border_width_left = 3
	hover_style.border_width_top = 3
	hover_style.border_width_right = 3
	hover_style.border_width_bottom = 3
	hover_style.border_color = Color(bg_color.r * 0.6, bg_color.g * 0.6, bg_color.b * 0.6, 1.0)
	
	# Create StyleBoxFlat for pressed state
	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(bg_color.r * 0.85, bg_color.g * 0.85, bg_color.b * 0.85, 1.0)  # Darker when pressed
	pressed_style.corner_radius_top_left = 12
	pressed_style.corner_radius_top_right = 12
	pressed_style.corner_radius_bottom_left = 12
	pressed_style.corner_radius_bottom_right = 12
	pressed_style.border_width_left = 3
	pressed_style.border_width_top = 3
	pressed_style.border_width_right = 3
	pressed_style.border_width_bottom = 3
	pressed_style.border_color = Color(bg_color.r * 0.5, bg_color.g * 0.5, bg_color.b * 0.5, 1.0)
	
	# Apply the custom styles to the button
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style) 
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("focus", hover_style)  # Use hover style for focus

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
			
			# Apply the theme's styling to the button itself
			apply_theme_to_button(button, i, theme_data)
			
			# Create simple tile preview using theme config specification
			create_simple_tile_preview(button, i, theme_data)
			
			# Setup background color preview (if there's a ColorRect for it)
			var bg_preview_name = "BackgroundPreview" + str(i)
			var bg_preview = button.get_node_or_null(bg_preview_name) as ColorRect
			if bg_preview:
				background_previews.append(bg_preview)
				bg_preview.color = theme_data["background_color"]

func create_simple_tile_preview(button: Button, theme_index: int, theme_data: Dictionary):
	"""Create a single tile preview using the preview_face specification from theme config"""
	
	# Remove existing preview if it exists
	var old_preview_name = "TilesetPreview" + str(theme_index)
	var old_preview = button.get_node_or_null(old_preview_name)
	if old_preview:
		old_preview.queue_free()
	
	var old_enhanced_preview_name = "EnhancedPreview" + str(theme_index)
	var old_enhanced_preview = button.get_node_or_null(old_enhanced_preview_name)
	if old_enhanced_preview:
		old_enhanced_preview.queue_free()
	
	# Load the tileset
	var tile_sprites = load(theme_data["tileset_path"]) as UnifiedTileSprites
	if not tile_sprites:
		print("TilesetSelection: Failed to load unified tile sprites from: ", theme_data["tileset_path"])
		return
	
	# Calculate 75% of button size for preview
	var button_size = button.custom_minimum_size
	var preview_size = Vector2(button_size.x * 0.75, button_size.y * 0.75)
	var half_preview = preview_size / 2
	
	# Create single tile preview directly on the button (no background frame needed)
	# Make tile 70% of the button size for good visibility
	var tile_size = Vector2(button_size.x * 0.7, button_size.y * 0.7)
	var half_tile = tile_size / 2
	var tile_rect = TextureRect.new()
	tile_rect.name = "TilesetPreview" + str(theme_index)
	tile_rect.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	tile_rect.position = Vector2(-half_tile.x, -half_tile.y)
	tile_rect.size = tile_size
	tile_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tile_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(tile_rect)
	
	# Get the preview face index from theme config, default to 0
	var preview_face = theme_data.get("preview_face", 0)
	var texture = tile_sprites.get_pipe_texture(preview_face)
	if texture:
		tile_rect.texture = texture
	
	# Store single tile reference for potential future use
	theme_previews.append([tile_rect])


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
	
	# Check if theme was changed and show interstitial ad
	if GameState.check_and_reset_theme_changed():
		_show_theme_change_interstitial()
		
	get_tree().change_scene_to_file("res://TitleScreen.tscn")

func _show_theme_change_interstitial():
	# TODO: Implement actual ad display logic here
	# This is where you would add your ad display implementation
	print("Showing interstitial ad after theme change")
	
	# Check if interstitial ad is ready and show it
	if AdMobManager.is_interstitial_ad_ready():
		print("show interstitial ad...")
		AdMobManager.show_interstitial()
	else:
		print("Interstitial ad not ready, loading and waiting...")
		# Connect to the loaded signal to show ad when ready
		_wait_for_interstitial_and_show()

func _wait_for_interstitial_and_show():
	# Connect to ad loaded signal
	AdMobManager.interstitial_ad_loaded.connect(_on_interstitial_loaded, CONNECT_ONE_SHOT)
	AdMobManager.interstitial_ad_failed_to_load.connect(_on_interstitial_failed, CONNECT_ONE_SHOT)
	
	# Load the ad
	AdMobManager.load_interstitial()

func _on_interstitial_loaded():
	print("Interstitial ad loaded, showing now...")
	AdMobManager.show_interstitial()

func _on_interstitial_failed(error):
	print("Failed to load interstitial ad for theme change: ", error)

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
