extends Control

# Tileset Selection Screen
# Allows player to choose between available tilesets with previews

@onready var grid_container = $VBoxContainer/GridContainer
@onready var back_button = $VBoxContainer/ButtonContainer/BackButton

var tileset_buttons: Array[Button] = []
var tileset_previews: Array[TextureRect] = []

func _ready():
	setup_tileset_buttons()
	setup_previews()
	back_button.pressed.connect(_on_back_button_pressed)

func setup_tileset_buttons():
	# Get tileset buttons and connect signals
	for i in range(6):  # 6 total slots (3 active + 3 future)
		var button_name = "TilesetButton" + str(i)
		var button = grid_container.get_node(button_name)
		if button:
			tileset_buttons.append(button)
			if i < GameState.available_tilesets.size():
				# Active tileset
				button.pressed.connect(_on_tileset_button_pressed.bind(i))
				# Update button text with tileset name
				button.text = GameState.get_tileset_name(i)
				# Highlight selected tileset
				if i == GameState.selected_tileset_index:
					button.modulate = Color(1.2, 1.2, 1.0)  # Slight yellow tint
			else:
				# Future slot - keep disabled
				button.text = "Coming Soon"
				button.disabled = true

func setup_previews():
	# Setup preview textures for available tilesets
	for i in range(3):  # Only for active tilesets
		if i >= tileset_buttons.size():
			continue
			
		var preview_name = "TilesetPreview" + str(i)
		var button = tileset_buttons[i]
		var preview = button.get_node(preview_name) as TextureRect
		if preview and i < GameState.available_tilesets.size():
			tileset_previews.append(preview)
			
			# Load the tileset and get preview texture
			var tileset_data = GameState.available_tilesets[i]
			var pipe_sprites = load(tileset_data["resource"]) as PipeSprites
			if pipe_sprites:
				var preview_texture = pipe_sprites.get_pipe_texture(tileset_data["preview_face"])
				if preview_texture:
					preview.texture = preview_texture

func _on_tileset_button_pressed(index: int):
	# Update selection in GameState
	GameState.set_selected_tileset(index)
	
	# Update visual feedback
	update_selection_highlight()
	
	# Optional: Play sound effect
	GameState.play_sound("click")

func update_selection_highlight():
	# Reset all button colors
	for i in range(tileset_buttons.size()):
		if i < GameState.available_tilesets.size() and i < tileset_buttons.size():
			if i == GameState.selected_tileset_index:
				tileset_buttons[i].modulate = Color(1.2, 1.2, 1.0)  # Yellow highlight
			else:
				tileset_buttons[i].modulate = Color.WHITE

func _on_back_button_pressed():
	# Return to title screen
	GameState.play_sound("click")
	get_tree().change_scene_to_file("res://TitleScreen.tscn")