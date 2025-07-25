extends Control

func _ready():
	# Set up responsive title sizing based on screen dimensions
	_setup_title_sizing()

func _setup_title_sizing():
	var title_shadow = $TitleContainer/TitleShadow
	var main_title = $TitleContainer/MainTitle
	
	# Calculate font size based on viewport dimensions
	var viewport_size = get_viewport().get_visible_rect().size
	var font_size = min(viewport_size.x * 0.08, 50)  # Max 50px, scaled by width
	
	title_shadow.add_theme_font_size_override("font_size", font_size)
	main_title.add_theme_font_size_override("font_size", font_size)
	
	# Update shadow offset based on viewport size
	var shadow_offset = min(viewport_size.x * 0.01, 5)
	title_shadow.position.x = shadow_offset
	title_shadow.position.y = shadow_offset

func _on_start_button_pressed():
	# Navigate to PlayScreen
	get_tree().change_scene_to_file("res://PlayScreen.tscn")

func _on_about_button_pressed():
	# Navigate to AboutScreen
	get_tree().change_scene_to_file("res://AboutScreen.tscn")
