extends Resource
class_name PipeSprites

# Pipe sprite resource with mapping and texture management
# Based on original linkage_test_green2.png sprite sheet

@export var sprite_texture: Texture2D
@export var tile_size: int = 64
@export var sheet_columns: int = 3
@export var sheet_rows: int = 4

# Sprite mapping for the 10 pipe faces (based on original JS mapping)
# Original formula: [64*Math.floor(i/3), 64*(i%3), 64, 64]
const PIPE_FACE_MAPPING = [
	Vector2i(0, 0),    # Face 0: V↑ (vertical up end)
	Vector2i(0, 64),   # Face 1: V| (vertical straight)
	Vector2i(0, 128),  # Face 2: V↓ (vertical down end)
	Vector2i(64, 0),   # Face 3: H→ (horizontal right end)
	Vector2i(64, 64),  # Face 4: └ (corner right-down)
	Vector2i(64, 128), # Face 5: ┘ (corner right-up)
	Vector2i(128, 0),  # Face 6: H─ (horizontal straight)
	Vector2i(128, 64), # Face 7: ┌ (corner left-down)
	Vector2i(128, 128),# Face 8: ┐ (corner left-up)
	Vector2i(192, 0)   # Face 9: H← (horizontal left end)
]

func _init():
	# Load the sprite texture
	sprite_texture = load("res://gameboard/resources/tile_sprites/linkage_test_green2.png")

# Get AtlasTexture for a specific pipe face
func get_pipe_texture(face: int) -> AtlasTexture:
	if not sprite_texture:
		push_error("PipeSprites: sprite_texture not loaded")
		return null
	
	if face < 0 or face >= PIPE_FACE_MAPPING.size():
		push_error("PipeSprites: invalid face index " + str(face))
		return null
	
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = sprite_texture
	
	var mapping = PIPE_FACE_MAPPING[face]
	atlas_texture.region = Rect2(mapping.x, mapping.y, tile_size, tile_size)
	
	return atlas_texture

# Get the UV coordinates for a face (for shader use)
func get_face_uv(face: int) -> Vector4:
	if not sprite_texture or face < 0 or face >= PIPE_FACE_MAPPING.size():
		return Vector4.ZERO
	
	var texture_size = sprite_texture.get_size()
	var mapping = PIPE_FACE_MAPPING[face]
	
	# Return UV coordinates as Vector4(u_min, v_min, u_max, v_max)
	return Vector4(
		float(mapping.x) / texture_size.x,
		float(mapping.y) / texture_size.y,
		float(mapping.x + tile_size) / texture_size.x,
		float(mapping.y + tile_size) / texture_size.y
	)

# Validate the sprite sheet dimensions
func validate_sprite_sheet() -> bool:
	if not sprite_texture:
		return false
	
	var expected_size = Vector2i(tile_size * sheet_columns, tile_size * sheet_rows)
	var actual_size = sprite_texture.get_size()
	
	if actual_size != (expected_size as Vector2):
		push_warning("PipeSprites: Expected size " + str(expected_size) + " but got " + str(actual_size))
		return false
	
	return true

# Get all pipe face names for debugging
func get_pipe_face_names() -> Array[String]:
	return ["V↑", "V|", "V↓", "H→", "└", "┘", "H─", "┌", "┐", "H←"]
