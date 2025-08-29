extends Resource
class_name FadeSprites

# Fade sprite resource for tile removal animations
# Uses green_fade.png sprite sheet with 5 animation frames

@export var sprite_texture: Texture2D
@export var tile_size: int = 64
@export var animation_frames: int = 5

# Custom face-to-row mapping - modify this array to change which sprite sheet row each pipe face uses

const FACE_TO_ROW_MAPPING = [0, 4, 1, 2, 6, 7, 5, 8, 9, 3] 

# Fade frame mapping - 5 frames arranged horizontally per row, 10 rows (one per pipe face)
# Each pipe face (0-9) has its own row with 5 fade frames
# Frame 0: Full opacity, Frame 4: Nearly transparent

func _init():
	# Load the fade sprite texture
	sprite_texture = load("res://assets/sprites/green_fade.png")

# Get AtlasTexture for a specific fade frame (uses face 0 for backward compatibility)
func get_fade_texture(frame: int) -> AtlasTexture:
	return get_fade_texture_for_face(frame, 0)

# Get AtlasTexture for a specific fade frame and pipe face
func get_fade_texture_for_face(frame: int, face: int) -> AtlasTexture:
	if not sprite_texture:
		push_error("FadeSprites: sprite_texture not loaded")
		return null
	
	if frame < 0 or frame >= animation_frames:
		push_error("FadeSprites: invalid frame index " + str(frame))
		return null
		
	if face < 0 or face > 9:
		push_error("FadeSprites: invalid face index " + str(face) + " (must be 0-9)")
		return null
	
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = sprite_texture
	
	# Calculate position using custom face-to-row mapping
	var frame_x = frame * tile_size
	var mapped_row = FACE_TO_ROW_MAPPING[face]
	var row_y = mapped_row * tile_size
	atlas_texture.region = Rect2(frame_x, row_y, tile_size, tile_size)
	
	return atlas_texture

# Get UV coordinates for a fade frame (for shader use)
func get_frame_uv(frame: int, face: int = 0) -> Vector4:
	if not sprite_texture or frame < 0 or frame >= animation_frames or face < 0 or face > 9:
		return Vector4.ZERO
	
	var texture_size = sprite_texture.get_size()
	var frame_x = frame * tile_size
	var mapped_row = FACE_TO_ROW_MAPPING[face]
	var row_y = mapped_row * tile_size
	
	# Return UV coordinates as Vector4(u_min, v_min, u_max, v_max)
	return Vector4(
		float(frame_x) / texture_size.x,
		float(row_y) / texture_size.y,
		float(frame_x + tile_size) / texture_size.x,
		float(row_y + tile_size) / texture_size.y
	)

# Validate the fade sprite sheet dimensions
func validate_sprite_sheet() -> bool:
	if not sprite_texture:
		return false
	
	var expected_width = tile_size * animation_frames  # 5 frames horizontally
	var expected_height = tile_size * 10  # 10 rows (one per pipe face)
	var actual_size = sprite_texture.get_size()
	
	if actual_size.x != expected_width or actual_size.y != expected_height:
		push_warning("FadeSprites: Expected size " + str(Vector2i(expected_width, expected_height)) + " but got " + str(actual_size))
		return false
	
	return true

# Get total number of animation frames
func get_frame_count() -> int:
	return animation_frames
