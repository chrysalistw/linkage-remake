# UnifiedTileSprites Manual

## Overview
`UnifiedTileSprites` is a Godot 4 resource that manages both static pipe sprites and smooth fade animations from a single sprite sheet. It provides both legacy timer-based animations and modern AnimatedSprite2D-based animations for better performance.

## Sprite Sheet Layout

### Expected Layout
The sprite sheet should be organized as a grid where:
- **Columns (X-axis)**: Each column represents a different pipe face (0-9)
- **Rows (Y-axis)**: Each row represents a different animation frame (0-4)

```
    Face0  Face1  Face2  Face3  Face4  Face5  Face6  Face7  Face8  Face9
Row0 [Still] [Still] [Still] [Still] [Still] [Still] [Still] [Still] [Still] [Still]
Row1 [Fade1] [Fade1] [Fade1] [Fade1] [Fade1] [Fade1] [Fade1] [Fade1] [Fade1] [Fade1]
Row2 [Fade2] [Fade2] [Fade2] [Fade2] [Fade2] [Fade2] [Fade2] [Fade2] [Fade2] [Fade2]
Row3 [Fade3] [Fade3] [Fade3] [Fade3] [Fade3] [Fade3] [Fade3] [Fade3] [Fade3] [Fade3]
Row4 [Fade4] [Fade4] [Fade4] [Fade4] [Fade4] [Fade4] [Fade4] [Fade4] [Fade4] [Fade4]
```

### Dimensions
- **Total Size**: 640x320 pixels (10 columns × 5 rows, 64px tiles)
- **Tile Size**: 64x64 pixels
- **Columns**: 10 (one per pipe face)
- **Rows**: 5 (animation progression from still to fully faded)

## Configuration

### Export Variables
```gdscript
@export var sprite_texture: Texture2D         # The main sprite sheet
@export var tile_size: int = 64              # Size of each tile in pixels
@export var sheet_columns: int = 10          # Number of columns (faces)
@export var sheet_rows: int = 5              # Number of rows (animation frames)
@export var static_face_count: int = 10      # Number of different pipe faces
@export var static_rows: int = 1             # Rows used for static sprites
@export var animation_frames: int = 5        # Number of animation frames
@export var animation_rows: int = 5          # Total rows used for animations
@export var animation_start_row: int = 0     # Starting row for animations
@export var animation_fps: float = 10.0      # Animation speed (frames per second)
```

### Resource Setup (.tres file)
```ini
[resource]
script = ExtResource("UnifiedTileSprites.gd")
sprite_texture = ExtResource("your_sprite_sheet.png")
tile_size = 64
sheet_columns = 10
sheet_rows = 5
static_face_count = 10
static_rows = 1
animation_frames = 5
animation_rows = 5
animation_start_row = 0
animation_fps = 10.0
```

## Usage

### 1. Static Pipe Sprites

#### Get Static Texture
```gdscript
var unified_sprites = load("res://path/to/your_tileset.tres")
var pipe_texture = unified_sprites.get_pipe_texture(face_index)  # face_index: 0-9
sprite.texture = pipe_texture
```

#### Get UV Coordinates (for shaders)
```gdscript
var uv_coords = unified_sprites.get_face_uv(face_index)  # Returns Vector4
```

### 2. Legacy Animation System

#### Basic Animation
```gdscript
# Get animation frame texture
var frame_texture = unified_sprites.get_fade_texture_for_face(frame, face)
sprite.texture = frame_texture

# Manual frame cycling
for frame in range(unified_sprites.get_frame_count()):
    var texture = unified_sprites.get_fade_texture_for_face(frame, face)
    sprite.texture = texture
    await get_tree().create_timer(0.1).timeout  # Wait 100ms
```

### 3. Modern Animation System (Recommended)

#### Using AnimationController
```gdscript
# Create animation controller
var controller = unified_sprites.create_animation_controller(face_index)
add_child(controller)

# Connect signals
controller.animation_started.connect(_on_animation_started)
controller.animation_finished.connect(_on_animation_finished)
controller.animation_frame_changed.connect(_on_frame_changed)

# Control animation
controller.play_animation()      # Start animation
controller.pause_animation()     # Pause
controller.resume_animation()    # Resume
controller.stop_animation()      # Stop and reset
controller.restart_animation()   # Restart from beginning
```

#### Using SpriteFrames Directly
```gdscript
# Create SpriteFrames resource
var sprite_frames = unified_sprites.create_sprite_frames_for_face(face_index)

# Create AnimatedSprite2D
var animated_sprite = AnimatedSprite2D.new()
animated_sprite.sprite_frames = sprite_frames
animated_sprite.animation = "fade"
add_child(animated_sprite)

# Play animation
animated_sprite.play("fade")
```

#### Using AnimatedSprite2D Helper
```gdscript
# Quick setup
var animated_sprite = unified_sprites.create_animated_sprite_for_face(face_index)
add_child(animated_sprite)
animated_sprite.play("fade")
```

## Animation Controller API

### Signals
- `animation_started()` - Emitted when animation begins
- `animation_finished()` - Emitted when animation completes
- `animation_frame_changed(frame: int)` - Emitted on each frame change

### Methods
- `play_animation()` - Start the fade animation
- `pause_animation()` - Pause the current animation
- `resume_animation()` - Resume paused animation
- `stop_animation()` - Stop and reset to frame 0
- `restart_animation()` - Stop and immediately restart
- `get_animation_progress() -> float` - Get progress (0.0 to 1.0)
- `set_animation_progress(progress: float)` - Set specific progress
- `is_animation_playing() -> bool` - Check if playing
- `is_animation_paused() -> bool` - Check if paused
- `get_current_frame() -> int` - Get current frame index
- `get_animated_sprite() -> AnimatedSprite2D` - Get the sprite node

## Performance Optimization

### Caching
The system automatically caches `SpriteFrames` resources to avoid recreating them:
```gdscript
# Clear cache when sprite sheet changes
unified_sprites.clear_animation_cache()

# Preload all animations at startup (optional)
unified_sprites.preload_all_animations()
```

### Memory Management
- Animation controllers are automatically cleaned up when animations finish
- Use `queue_free()` on controllers when no longer needed
- Static textures are created on-demand and not cached

## Validation

### Sprite Sheet Validation
```gdscript
# Validate sprite sheet dimensions
if unified_sprites.validate_unified_sheet():
    print("Sprite sheet is valid")
else:
    print("Sprite sheet validation failed - check console for details")
```

### Common Validation Errors
- **Incorrect dimensions**: Sprite sheet size doesn't match expected tile count
- **Missing texture**: `sprite_texture` not assigned
- **Invalid face index**: Face index outside 0-9 range
- **Invalid frame index**: Frame index outside 0-4 range

## Migration from Legacy System

### Tile.gd Integration
The system supports both modern and legacy animation modes:
```gdscript
# Enable modern animation (default)
@export var use_modern_animation: bool = true

# Animation will automatically use the appropriate system
tile.start_fade_animation()
```

### Backward Compatibility
All existing methods remain functional:
- `get_fade_texture(frame)` - Still works for legacy code
- `get_fade_texture_for_face(frame, face)` - Still works
- `get_frame_uv(frame, face)` - Still works for shader use

## Troubleshooting

### Animation Not Playing
1. Check sprite sheet layout matches expected format
2. Verify `animation_fps > 0`
3. Ensure texture is properly assigned
4. Check console for validation errors

### Wrong Animation Position
1. Verify face index is 0-9
2. Check tile_size matches actual sprite dimensions
3. Ensure sprite sheet has exactly 10 columns and 5 rows

### Performance Issues
1. Use modern animation system instead of legacy
2. Call `preload_all_animations()` at startup
3. Avoid creating multiple controllers for the same face
4. Clean up controllers with `queue_free()` when done

## Example Implementation

See `gameboard/scripts/Tile.gd` for a complete implementation example showing how to integrate UnifiedTileSprites into a game tile system with both static display and fade animations.