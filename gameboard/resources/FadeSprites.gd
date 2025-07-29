extends Resource
class_name FadeSprites

# Fade sprite resource for tile removal animations
# Uses green_fade.png sprite sheet with 5 animation frames

@export var sprite_texture: Texture2D
@export var tile_size: int = 64
@export var animation_frames: int = 5

# Fade frame mapping - 5 frames arranged horizontally in green_fade.png
# Frame 0: Full opacity, Frame 4: Nearly transparent
const FADE_FRAME_MAPPING = [
	Vector2i(0, 0),     # Frame 0: Full green pipe
	Vector2i(64, 0),    # Frame 1: Slightly faded
	Vector2i(128, 0),   # Frame 2: More faded
	Vector2i(192, 0),   # Frame 3: Very faded
	Vector2i(256, 0)    # Frame 4: Almost transparent
]

func _init():
	# Load the fade sprite texture
	sprite_texture = load("res://linkage/imgs/tile_spr/green_fade.png")

# Get AtlasTexture for a specific fade frame
func get_fade_texture(frame: int) -> AtlasTexture:
	if not sprite_texture:
		push_error("FadeSprites: sprite_texture not loaded")
		return null
	
	if frame < 0 or frame >= FADE_FRAME_MAPPING.size():
		push_error("FadeSprites: invalid frame index " + str(frame))
		return null
	
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = sprite_texture
	
	var mapping = FADE_FRAME_MAPPING[frame]
	atlas_texture.region = Rect2(mapping.x, mapping.y, tile_size, tile_size)
	
	return atlas_texture

# Get UV coordinates for a fade frame (for shader use)
func get_frame_uv(frame: int) -> Vector4:
	if not sprite_texture or frame < 0 or frame >= FADE_FRAME_MAPPING.size():
		return Vector4.ZERO
	
	var texture_size = sprite_texture.get_size()
	var mapping = FADE_FRAME_MAPPING[frame]
	
	# Return UV coordinates as Vector4(u_min, v_min, u_max, v_max)
	return Vector4(
		float(mapping.x) / texture_size.x,
		float(mapping.y) / texture_size.y,
		float(mapping.x + tile_size) / texture_size.x,
		float(mapping.y + tile_size) / texture_size.y
	)

# Validate the fade sprite sheet dimensions
func validate_sprite_sheet() -> bool:
	if not sprite_texture:
		return false
	
	var expected_width = tile_size * animation_frames
	var expected_height = tile_size
	var actual_size = sprite_texture.get_size()
	
	if actual_size.x != expected_width or actual_size.y != expected_height:
		push_warning("FadeSprites: Expected size " + str(Vector2i(expected_width, expected_height)) + " but got " + str(actual_size))
		return false
	
	return true

# Get total number of animation frames
func get_frame_count() -> int:
	return animation_frames
