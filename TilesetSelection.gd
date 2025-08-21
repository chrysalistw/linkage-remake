extends Control

# Theme Selection Screen
# Allows player to choose between available theme packages (tileset + background + UI theme)

@onready var grid_container = $VBoxContainer/GridContainer
@onready var back_button = $VBoxContainer/BackButton
@onready var background = $Background

var theme_buttons: Array[Button] = []
var theme_previews: Array[TextureRect] = []
var background_previews: Array[ColorRect] = []
var selection_borders: Array[ColorRect] = []
var selection_labels: Array[Label] = []

func _ready():
	setup_theme_buttons()
	setup_previews()
	back_button.pressed.connect(_on_back_button_pressed)
	
	# Apply current theme
	_apply_current_theme()
	_connect_theme_signals()

func setup_theme_buttons():
	# Get theme buttons and connect signals
	for i in range(6):  # 6 total slots (3 active + 3 future)
		var button_name = "TilesetButton" + str(i)
		var button = grid_container.get_node(button_name)
		if button:
			theme_buttons.append(button)
			
			# Create selection border for each button
			var border = ColorRect.new()
			border.mouse_filter = Control.MOUSE_FILTER_IGNORE
			border.color = Color.TRANSPARENT
			border.size = button.size + Vector2(8, 8)  # 4px border on each side
			border.position = Vector2(-4, -4)  # Offset to center the border
			button.add_child(border)
			button.move_child(border, 0)  # Move border to first child (behind content)
			selection_borders.append(border)
			
			# Create "SELECTED" label for each button
			var label = Label.new()
			label.text = "✓ SELECTED"
			label.modulate = Color.TRANSPARENT  # Initially hidden
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			label.add_theme_font_size_override("font_size", 14)
			label.add_theme_color_override("font_color", Color.WHITE)
			label.add_theme_color_override("font_shadow_color", Color.BLACK)
			label.add_theme_constant_override("shadow_offset_x", 1)
			label.add_theme_constant_override("shadow_offset_y", 1)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.position = Vector2(0, button.size.y - 25)  # Bottom of button
			label.size = Vector2(button.size.x, 20)
			button.add_child(label)
			selection_labels.append(label)
			
			if i < GameState.get_theme_count():
				# Active theme
				button.pressed.connect(_on_theme_button_pressed.bind(i))
				# Update button text with theme name
				button.text = GameState.get_theme_name(i)
			else:
				# Future slot - keep disabled
				button.text = "Coming Soon"
				button.disabled = true
	
	# Apply initial highlight after all buttons are set up
	update_selection_highlight()

func setup_previews():
	# Setup preview textures and background colors for available themes
	for i in range(3):  # Only for active themes
		if i >= theme_buttons.size():
			continue
			
		var button = theme_buttons[i]
		if i < GameState.get_theme_count():
			var theme_data = GameState.available_themes[i]
			
			# Setup tileset preview
			var preview_name = "TilesetPreview" + str(i)
			var preview = button.get_node(preview_name) as TextureRect
			if preview:
				theme_previews.append(preview)
				var pipe_sprites = load(theme_data["tileset_resource"]) as PipeSprites
				if pipe_sprites:
					var preview_texture = pipe_sprites.get_pipe_texture(theme_data["preview_face"])
					if preview_texture:
						preview.texture = preview_texture
			
			# Setup background color preview (if there's a ColorRect for it)
			var bg_preview_name = "BackgroundPreview" + str(i)
			var bg_preview = button.get_node_or_null(bg_preview_name) as ColorRect
			if bg_preview:
				background_previews.append(bg_preview)
				bg_preview.color = theme_data["background_color"]

func _on_theme_button_pressed(index: int):
	# Update theme selection in GameState
	GameState.set_selected_theme(index)
	
	# Update visual feedback
	update_selection_highlight()
	
	# Optional: Play sound effect
	GameState.play_sound("click")

func update_selection_highlight():
	# Reset all button colors, borders, and labels
	for i in range(theme_buttons.size()):
		if i < GameState.get_theme_count() and i < theme_buttons.size():
			if i == GameState.selected_theme_index:
				# Selected theme - more prominent highlight
				theme_buttons[i].modulate = Color(1.4, 1.4, 1.1)  # Brighter highlight
				
				# Add colored border based on theme
				if i < selection_borders.size():
					var theme_data = GameState.available_themes[i]
					var border_color = _get_theme_accent_color(theme_data)
					selection_borders[i].color = border_color
				
				# Show "SELECTED" label with matching color
				if i < selection_labels.size():
					selection_labels[i].modulate = Color.WHITE  # Make label visible
					var theme_data = GameState.available_themes[i]
					var accent_color = _get_theme_accent_color(theme_data)
					selection_labels[i].add_theme_color_override("font_color", accent_color)
			else:
				# Unselected theme - normal appearance
				theme_buttons[i].modulate = Color.WHITE
				if i < selection_borders.size():
					selection_borders[i].color = Color.TRANSPARENT
				if i < selection_labels.size():
					selection_labels[i].modulate = Color.TRANSPARENT  # Hide label

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
	# Also update selection highlight
	update_selection_highlight()

func _apply_current_theme():
	var theme_data = GameState.get_selected_theme_data()
	_apply_theme(theme_data)

func _apply_theme(theme_data: Dictionary):
	# Apply background color
	if background and theme_data.has("background_color"):
		background.color = theme_data["background_color"]
	
	# Apply theme resource
	if theme_data.has("theme_resource"):
		var theme_resource = load(theme_data["theme_resource"])
		if theme_resource:
			theme = theme_resource
