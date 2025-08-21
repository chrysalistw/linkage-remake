extends Control

var _ad_view : AdView 
@onready var background = $Background

func _ready():
	MobileAds.initialize()
	# Set up responsive title sizing based on screen dimensions
	_setup_title_sizing()
	
	# Apply current theme
	_apply_current_theme()
	_connect_theme_signals()
	
	_load_banner()

func _setup_title_sizing():
	var title_shadow = $TitleContainer/TitleShadow
	var main_title = $TitleContainer/MainTitle
	
	# Calculate font size based on viewport dimensions
	#var viewport_size = get_viewport().get_visible_rect().size
	#var font_size = min(viewport_size.x * 0.08, 50)  # Max 50px, scaled by width
	
	#title_shadow.add_theme_font_size_override("font_size", font_size)
	#main_title.add_theme_font_size_override("font_size", font_size)
	
	# Update shadow offset based on viewport size
	#var shadow_offset = min(viewport_size.x * 0.01, 5)
	#title_shadow.position.x = shadow_offset
	#title_shadow.position.y = shadow_offset
func _create_ad_view() -> void:
	 #free memory
	if _ad_view:
		_ad_view.destroy()
		_ad_view = null

	var unit_id : String = "ca-app-pub-3940256099942544/9214589741"

	_ad_view = AdView.new(unit_id, AdSize.BANNER, AdPosition.Values.TOP)
func _load_banner():
	if _ad_view == null:
		_create_ad_view()
	var ad_request := AdRequest.new()
	_ad_view.load_ad(ad_request)
func _on_start_button_pressed():
	# Navigate to PlayScreen
	get_tree().change_scene_to_file("res://PlayScreen.tscn")

func _on_tileset_button_pressed():
	# Navigate to TilesetSelection screen
	get_tree().change_scene_to_file("res://TilesetSelection.tscn")

func _on_about_button_pressed():
	# Navigate to AboutScreen
	get_tree().change_scene_to_file("res://AboutScreen.tscn")

func _connect_theme_signals():
	# Connect to theme change signal
	GameState.theme_changed.connect(_on_theme_changed)

func _on_theme_changed(theme_data: Dictionary):
	_apply_theme(theme_data)

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
