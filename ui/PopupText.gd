extends Label

# PopupText - Animated text popup for score/move changes
# Shows "+n" text with color coding (red for score, blue for moves)

enum PopupType {
	SCORE,
	MOVES
}

var popup_type: PopupType
var original_position: Vector2
var animation_duration: float = 1.0

func _ready():
	# Start invisible
	modulate.a = 0.0
	
func setup_popup(text_content: String, type: PopupType, start_position: Vector2):
	text = text_content
	popup_type = type
	original_position = start_position
	position = start_position
	
	# Set color and styling based on type
	if popup_type == PopupType.SCORE:
		add_theme_color_override("font_color", Color(0.9, 0.2, 0.2, 1.0))  # Bright red for score
	else:
		add_theme_color_override("font_color", Color(0.2, 0.4, 0.9, 1.0))  # Bright blue for moves
	
	# Start with transparent modulate for fade-in animation
	modulate = Color(1.0, 1.0, 1.0, 0.0)
	
	# Set font size and styling for visibility
	add_theme_font_size_override("font_size", 28)
	
	# Add outline for better visibility
	add_theme_color_override("font_shadow_color", Color.BLACK)
	add_theme_constant_override("shadow_offset_x", 2)
	add_theme_constant_override("shadow_offset_y", 2)
	
	# Start the animation
	animate_popup()

func animate_popup():
	# Create tween for popup animation
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade in quickly with bounce effect
	tween.tween_property(self, "modulate:a", 1.0, 0.15)
	
	# Move up with slight curve
	tween.tween_property(self, "position:y", original_position.y - 60, animation_duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	# Scale animation with bounce for emphasis
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3).set_delay(0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Fade out smoothly at the end
	tween.tween_property(self, "modulate:a", 0.0, 0.4).set_delay(0.6)
	
	# Clean up after animation
	tween.tween_callback(_cleanup).set_delay(animation_duration)

func _cleanup():
	queue_free()
