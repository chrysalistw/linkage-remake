extends Resource
class_name UnifiedTileSprites

# Unified tile sprite resource combining static pipes and smooth fade animations
# Uses Godot's built-in animation system for better performance and control

@export var sprite_texture: Texture2D
@export var tile_size: int = 64
@export var sheet_columns: int = 3
@export var sheet_rows: int = 4

# Static pipe configuration
@export var static_face_count: int = 10
@export var static_rows: int = 4

# Animation configuration  
@export var animation_frames: int = 5  # Rows 0-4 (0=still, 1-4=fade progression)
@export var animation_rows: int = 5   # Total animation rows used
@export var animation_start_row: int = 0  # Animations start at row 0
@export var animation_fps: float = 10.0  # Frames per second for animations

# Sprite mapping for the 10 pipe faces (row-based layout)
const PIPE_FACE_MAPPING = [
	Vector2i(0, 0),
	Vector2i(0, 64*1),
	Vector2i(0, 64*2),
	Vector2i(0, 64*3),
	Vector2i(0, 64*6),
	Vector2i(0, 64*7),
	Vector2i(0, 64*4),
	Vector2i(0, 64*8),
	Vector2i(0, 64*9),
	Vector2i(0, 64*5)
]

# No longer needed - each face is in its own column, each frame is in its own row
# const FACE_TO_ROW_MAPPING = [0, 1, 2, 3, 6, 9, 4, 5, 7, 8]  # DEPRECATED

# Cached SpriteFrames resources for each face
var _sprite_frames_cache: Dictionary = {} 

func _init():
	# Initialize animation cache
	_sprite_frames_cache.clear()
	# Clear cache when layout changes
	call_deferred("clear_animation_cache")

# STATIC PIPE METHODS - Compatible with PipeSprites interface

# Get AtlasTexture for a static pipe face
func get_pipe_texture(face: int) -> AtlasTexture:
	if not sprite_texture:
		push_error("UnifiedTileSprites: sprite_texture not loaded")
		return null
	
	if face < 0 or face >= PIPE_FACE_MAPPING.size():
		push_error("UnifiedTileSprites: invalid face index " + str(face))
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
	
	return Vector4(
		float(mapping.x) / texture_size.x,
		float(mapping.y) / texture_size.y,
		float(mapping.x + tile_size) / texture_size.x,
		float(mapping.y + tile_size) / texture_size.y
	)

# ANIMATION METHODS - Modern Godot animation system

# Get AtlasTexture for animation frame (backward compatibility)
func get_fade_texture(frame: int) -> AtlasTexture:
	return get_fade_texture_for_face(frame, 0)

# Get AtlasTexture for specific animation frame and pipe face (backward compatibility)
func get_fade_texture_for_face(frame: int, face: int) -> AtlasTexture:
	if not sprite_texture:
		push_error("UnifiedTileSprites: sprite_texture not loaded")
		return null
	
	if frame < 0 or frame >= animation_frames:
		push_error("UnifiedTileSprites: invalid frame index " + str(frame))
		return null
		
	if face < 0 or face > 9:
		push_error("UnifiedTileSprites: invalid face index " + str(face) + " (must be 0-9)")
		return null
	
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = sprite_texture
	
	# Calculate position using PIPE_FACE_MAPPING for consistency with static pipes
	if face >= PIPE_FACE_MAPPING.size():
		push_error("UnifiedTileSprites: invalid face index for animation " + str(face))
		return null
	
	var face_mapping = PIPE_FACE_MAPPING[face]
	var frame_x = frame * tile_size  # Each frame is in its own column (0=still, 1-4=fade)
	atlas_texture.region = Rect2(frame_x, face_mapping.y, tile_size, tile_size)
	
	return atlas_texture

# Create SpriteFrames resource for specific face animation
func create_sprite_frames_for_face(face: int) -> SpriteFrames:
	if face < 0 or face > 9:
		push_error("UnifiedTileSprites: invalid face index " + str(face))
		return null
	
	# Check cache first
	var cache_key = "face_" + str(face)
	if _sprite_frames_cache.has(cache_key):
		return _sprite_frames_cache[cache_key]
	
	if not sprite_texture:
		push_error("UnifiedTileSprites: sprite_texture not loaded")
		return null
	
	var sprite_frames = SpriteFrames.new()
	sprite_frames.add_animation("fade")
	sprite_frames.set_animation_loop("fade", false)  # Don't loop fade animation
	sprite_frames.set_animation_speed("fade", animation_fps)
	
	# Add all animation frames for this face using PIPE_FACE_MAPPING
	if face >= PIPE_FACE_MAPPING.size():
		push_error("UnifiedTileSprites: invalid face index for SpriteFrames " + str(face))
		return null
	
	var face_mapping = PIPE_FACE_MAPPING[face]
	
	for frame in range(animation_frames):
		var atlas_texture = AtlasTexture.new()
		atlas_texture.atlas = sprite_texture
		var frame_x = frame * tile_size  # Frame determines column
		atlas_texture.region = Rect2(frame_x, face_mapping.y, tile_size, tile_size)
		sprite_frames.add_frame("fade", atlas_texture)
	
	# Cache the result
	_sprite_frames_cache[cache_key] = sprite_frames
	return sprite_frames

# Create and configure an AnimatedSprite2D node for face animation
func create_animated_sprite_for_face(face: int) -> AnimatedSprite2D:
	var sprite_frames = create_sprite_frames_for_face(face)
	if not sprite_frames:
		return null
	
	var animated_sprite = AnimatedSprite2D.new()
	animated_sprite.sprite_frames = sprite_frames
	animated_sprite.animation = "fade"
	animated_sprite.frame = 0
	
	return animated_sprite

# Get UV coordinates for animation frame (for shader use)
func get_frame_uv(frame: int, face: int = 0) -> Vector4:
	if not sprite_texture or frame < 0 or frame >= animation_frames or face < 0 or face > 9:
		return Vector4.ZERO
	
	var texture_size = sprite_texture.get_size()
	
	if face >= PIPE_FACE_MAPPING.size():
		return Vector4.ZERO
	
	var face_mapping = PIPE_FACE_MAPPING[face]
	var frame_x = frame * tile_size  # Frame determines column
	
	return Vector4(
		float(frame_x) / texture_size.x,
		float(face_mapping.y) / texture_size.y,
		float(frame_x + tile_size) / texture_size.x,
		float(face_mapping.y + tile_size) / texture_size.y
	)

# Get total number of animation frames
func get_frame_count() -> int:
	return animation_frames

# Get animation FPS
func get_animation_fps() -> float:
	return animation_fps

# Get animation duration in seconds
func get_animation_duration() -> float:
	return float(animation_frames) / animation_fps

# Clear cached SpriteFrames (useful when sprite_texture changes)
func clear_animation_cache():
	_sprite_frames_cache.clear()

# VALIDATION METHODS

# Validate the sprite sheet dimensions for static portion
func validate_sprite_sheet() -> bool:
	if not sprite_texture:
		return false
	
	var expected_width = tile_size * sheet_columns
	var min_expected_height = tile_size * (static_rows + animation_rows)
	var actual_size = sprite_texture.get_size()
	
	if actual_size.x < expected_width or actual_size.y < min_expected_height:
		push_warning("UnifiedTileSprites: Expected minimum size " + str(Vector2i(expected_width, min_expected_height)) + " but got " + str(actual_size))
		return false
	return true

# Validate animation portion of sprite sheet
func validate_animation_sheet() -> bool:
	if not sprite_texture:
		return false
	
	var expected_width = tile_size * animation_frames  
	var expected_height = tile_size * animation_rows
	var actual_size = sprite_texture.get_size()
	
	# Check if animation area fits within sprite
	var animation_area_width = expected_width
	var animation_area_height = expected_height
	
	if actual_size.x < animation_area_width:
		push_warning("UnifiedTileSprites: Animation area width " + str(animation_area_width) + " exceeds sprite width " + str(actual_size.x))
		return false
		
	if actual_size.y < (animation_start_row * tile_size + animation_area_height):
		push_warning("UnifiedTileSprites: Animation area doesn't fit in sprite height")
		return false
	
	return true

# Comprehensive validation
func validate_unified_sheet() -> bool:
	return validate_sprite_sheet() and validate_animation_sheet()

# Preload all animation frames into cache (optional performance optimization)
func preload_all_animations():
	for face in range(10):
		create_sprite_frames_for_face(face)

# ANIMATION CONTROLLER CLASS
# Modern animation controller with smooth controls and events
class TileAnimationController extends Node2D:
	signal animation_started
	signal animation_finished
	signal animation_frame_changed(frame: int)
	
	var unified_sprites: UnifiedTileSprites
	var animated_sprite: AnimatedSprite2D
	var face: int = 0
	var is_playing: bool = false
	var is_paused: bool = false
	
	func _init(sprites_resource: UnifiedTileSprites, tile_face: int):
		unified_sprites = sprites_resource
		face = tile_face
		_setup_animated_sprite()
	
	func _setup_animated_sprite():
		if not unified_sprites:
			return
		
		animated_sprite = unified_sprites.create_animated_sprite_for_face(face)
		if animated_sprite:
			add_child(animated_sprite)
			animated_sprite.animation_finished.connect(_on_animation_finished)
			animated_sprite.frame_changed.connect(_on_frame_changed)
	
	# Animation control methods
	func play_animation():
		if not animated_sprite or is_playing:
			return
		
		is_playing = true
		is_paused = false
		animated_sprite.play("fade")
		animation_started.emit()
	
	func pause_animation():
		if not animated_sprite or not is_playing or is_paused:
			return
		
		is_paused = true
		animated_sprite.pause()
	
	func resume_animation():
		if not animated_sprite or not is_playing or not is_paused:
			return
		
		is_paused = false
		animated_sprite.play()
	
	func stop_animation():
		if not animated_sprite:
			return
		
		is_playing = false
		is_paused = false
		animated_sprite.stop()
		animated_sprite.frame = 0
	
	func restart_animation():
		stop_animation()
		play_animation()
	
	# Get current animation progress (0.0 to 1.0)
	func get_animation_progress() -> float:
		if not animated_sprite or not unified_sprites:
			return 0.0
		
		var total_frames = unified_sprites.get_frame_count()
		if total_frames <= 0:
			return 0.0
		
		return float(animated_sprite.frame) / float(total_frames - 1)
	
	# Set animation to specific progress (0.0 to 1.0)
	func set_animation_progress(progress: float):
		if not animated_sprite or not unified_sprites:
			return
		
		progress = clamp(progress, 0.0, 1.0)
		var total_frames = unified_sprites.get_frame_count()
		var target_frame = int(progress * (total_frames - 1))
		animated_sprite.frame = target_frame
	
	# Event handlers
	func _on_animation_finished():
		is_playing = false
		is_paused = false
		animation_finished.emit()
	
	func _on_frame_changed():
		animation_frame_changed.emit(animated_sprite.frame)
	
	# Getters
	func is_animation_playing() -> bool:
		return is_playing and not is_paused
	
	func is_animation_paused() -> bool:
		return is_paused
	
	func get_current_frame() -> int:
		return animated_sprite.frame if animated_sprite else 0
	
	func get_animated_sprite() -> AnimatedSprite2D:
		return animated_sprite

# Factory method to create animation controller
func create_animation_controller(face: int) -> TileAnimationController:
	return TileAnimationController.new(self, face)
