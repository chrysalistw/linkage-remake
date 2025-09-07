extends Panel
class_name ItemDisplay

#@onready var item_icon: TextureRect = $HBoxContainer/ItemIcon
#@onready var item_label: Label = $HBoxContainer/ItemLabel

@export var icon_texture: Texture2D
@export var item_name: String = "Item"
@export var quantity: int = 0
@export var width: float
@export var height: float

func _ready():
	print($HBoxContainer/ItemLabel)
	_update_display()
	_connect_theme_signal()
	_apply_current_theme()

func _connect_theme_signal():
	if GameState.theme_changed.is_connected(_on_theme_changed):
		return
	GameState.theme_changed.connect(_on_theme_changed)

func _on_theme_changed(theme_data: Dictionary):
	_apply_theme(theme_data)

func _apply_current_theme():
	var theme_data = GameState.get_selected_theme_data()
	_apply_theme(theme_data)

func _apply_theme(theme_data: Dictionary):
	if theme_data.has("theme_path"):
		var theme_resource = load(theme_data["theme_path"])
		if theme_resource:
			theme = theme_resource

func _update_display():
	var item_icon = $HBoxContainer/ItemIcon
	var item_label = $HBoxContainer/ItemLabel
	prints("item_name: ", item_name)
	prints("quantity: ", quantity)
	#print(item_label)
	if not item_label:
		return
	if icon_texture and item_icon:
		item_icon.texture = icon_texture
		item_icon.visible = true
		item_label.text = "%s: %d" % [item_name, quantity]
	else:
		if item_icon:
			item_icon.visible = false
		item_label.text = "%s: %d" % [item_name, quantity]

func set_item_data(name: String, qty: int, icon: Texture2D = null):
	item_name = name
	quantity = qty
	icon_texture = icon
	_update_display()

func update_quantity(new_quantity: int):
	quantity = new_quantity
	_update_display()

func update_name(new_name: String):
	item_name = new_name
	_update_display()

func update_icon(new_icon: Texture2D):
	icon_texture = new_icon
	_update_display()
