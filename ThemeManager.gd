extends Node
class_name ThemeManager

var themes: Array[Dictionary] = []
var current_theme: Dictionary = {}

func _ready():
	load_themes()

func load_themes():
	var registry_path = "res://themes/theme_registry.json"
	var file = FileAccess.open(registry_path, FileAccess.READ)
	if not file:
		print("Failed to load theme registry")
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		print("Failed to parse theme registry JSON")
		return
	
	var registry = json.data
	themes.clear()
	
	for config_file in registry.themes:
		print("ThemeManager: Loading theme config: ", config_file)
		var theme_config = load_theme_config(config_file)
		if theme_config:
			print("ThemeManager: Successfully loaded theme: ", theme_config.get("name", "Unknown"))
			themes.append(theme_config)
		else:
			print("ThemeManager: Failed to load theme config: ", config_file)

func load_theme_config(config_path: String) -> Dictionary:
	var full_path = "res://" + config_path
	print("ThemeManager: Attempting to open: ", full_path)
	var file = FileAccess.open(full_path, FileAccess.READ)
	if not file:
		print("ThemeManager: Failed to load theme config: ", full_path)
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		print("Failed to parse theme config JSON: ", config_path)
		return {}
	
	return json.data

func get_theme_count() -> int:
	return themes.size()

func get_theme(index: int) -> Dictionary:
	if index >= 0 and index < themes.size():
		return themes[index]
	return {}

func get_theme_name(index: int) -> String:
	var theme = get_theme(index)
	return theme.get("name", "Unknown")

func set_current_theme(index: int):
	current_theme = get_theme(index)

func get_current_theme() -> Dictionary:
	return current_theme
