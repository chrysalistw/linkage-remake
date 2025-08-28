extends Control

@onready var background = $Background

func _ready():
	MobileAds.initialize()
	
	# Apply current theme
	_apply_current_theme()
	_connect_theme_signals()
	
	AdMobManager.load_banner()


func _on_start_button_pressed():
	# Navigate to PlayScreen
	#AdMobManager.load_interstitial()
	AdMobManager.load_rewarded()
	#get_tree().change_scene_to_file("res://PlayScreen.tscn")

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
