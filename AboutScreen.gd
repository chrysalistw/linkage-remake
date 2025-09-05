extends Control

@onready var star_button = $ContentContainer/StarContainer/StarButton
@onready var tutorial_dialog = $TutorialDialog
@onready var highscore_label = $ContentContainer/HighscoreLabel
@onready var background = $Background

var is_star_rotating: bool = false
var rotation_start_time: float = 0.0
var rotation_duration: float = 3.0

func _ready():
	_setup_screen()
	_load_highscore()
	
	# Apply current theme
	_apply_current_theme()
	_connect_theme_signals()

func _setup_screen():
	# Set up responsive title sizing based on screen dimensions
	var title_shadow = $TitleContainer/TitleShadow
	var about_title = $TitleContainer/AboutTitle
	
	# Calculate font size based on viewport dimensions
	var viewport_size = get_viewport().get_visible_rect().size
	var font_size = min(viewport_size.x * 0.06, 40)  # Max 40px, scaled by width
	
	title_shadow.add_theme_font_size_override("font_size", font_size)
	about_title.add_theme_font_size_override("font_size", font_size)
	
	# Update shadow offset based on viewport size
	var shadow_offset = min(viewport_size.x * 0.01, 5)
	title_shadow.position.x = shadow_offset
	title_shadow.position.y = shadow_offset

func _load_highscore():
	# Load actual high score from GameState
	highscore_label.text = "Highscore: " + str(GameState.high_score)

func _on_high_score_changed(new_high_score: int):
	# Update display when high score changes
	highscore_label.text = "Highscore: " + str(new_high_score)

func _process(delta):
	if is_star_rotating:
		var elapsed_time = Time.get_ticks_msec() - rotation_start_time
		if elapsed_time >= rotation_duration:
			is_star_rotating = false
			star_button.rotation = 0.0
		else:
			# Rotate the star during the animation
			var progress = elapsed_time / rotation_duration
			star_button.rotation = progress * 2.0 * PI

func _on_tutorial_button_pressed():
	tutorial_dialog.popup_centered()

func _on_star_button_pressed():
	# Start star rotation animation (3 seconds as per pseudocode)
	if not is_star_rotating:
		is_star_rotating = true
		rotation_start_time = Time.get_ticks_msec()

func _on_home_button_pressed():
	# Navigate back to title screen without dialog (show_dialog=false in pseudocode)
	get_tree().change_scene_to_file("res://TitleScreen.tscn")

func _on_ok_button_pressed():
	# Close tutorial dialog
	tutorial_dialog.hide()

func _connect_theme_signals():
	# Connect to theme change signal
	GameState.theme_changed.connect(_on_theme_changed)
	# Connect to high score updates
	GameState.high_score_changed.connect(_on_high_score_changed)

func _on_theme_changed(theme_data: Dictionary):
	_apply_theme(theme_data)

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
