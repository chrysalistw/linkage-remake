# GameBoard Structure: Dragging & Interactive Animation System

## Overview
The GameBoard implements a sophisticated drag-and-drop system for row/column manipulation with real-time visual feedback. The architecture separates concerns into specialized components that work together to provide smooth, responsive gameplay.

## Component Architecture

### Core Components & Interaction Flow

```
User Input → DragHandler → AnimationManager → RotationHandler → ConnectionManager
    ↓             ↓              ↓                ↓                    ↓
  Tile.gd    Visual Updates  Position Cache   Array Rotation    Connection Detection
```

## Dragging Mechanics Deep Dive

### 1. DragHandler.gd - Input Processing Engine

**Primary Responsibility**: Convert mouse/touch input into drag operations

#### Key Properties:
```gdscript
enum DragState { NONE, PREVIEW, HORIZONTAL, VERTICAL }
var drag_state: DragState = DragState.NONE
var is_dragging: bool = false
var start_tile_pos: Vector2i          # Grid position where drag began
var start_mouse_pos: Vector2          # Screen position where drag began  
var current_mouse_pos: Vector2        # Current mouse screen position
var drag_direction: Vector2           # Normalized direction (-1,0,1)
var pixel_displacement: Vector2       # Raw pixel movement for animations
```

#### Drag State Machine:
1. **NONE** → **PREVIEW**: User clicks on tile (`start_drag()`)
2. **PREVIEW** → **HORIZONTAL/VERTICAL**: Direction detected after 8px movement threshold
3. **HORIZONTAL/VERTICAL** → **NONE**: Mouse release triggers `drag_completed` signal

#### Direction Detection Logic (`detect_drag_direction()`):
```gdscript
# Only during PREVIEW state to prevent state flipping
if movement.length() > 8.0:  # 8px threshold
    if abs(movement.x) > abs(movement.y):
        drag_direction = Vector2(sign(movement.x), 0)  # ±1,0
        drag_state = DragState.HORIZONTAL
    else:
        drag_direction = Vector2(0, sign(movement.y))  # 0,±1  
        drag_state = DragState.VERTICAL
```

### 2. AnimationManager.gd - Visual Feedback System

**Primary Responsibility**: Provide real-time visual feedback during drag operations

#### Key Features:

##### Position Caching System:
```gdscript
var animated_positions_cache: Dictionary = {}
var cache_dirty: bool = true

# Efficient caching of animated positions
func get_cached_animated_position(row: int, col: int) -> Vector2:
    if cache_dirty:
        rebuild_position_cache()
    return animated_positions_cache.get(Vector2i(col, row), base_position)
```

##### Real-time Position Calculation (`get_animated_tile_position()`):
```gdscript
func get_animated_tile_position(row: int, col: int) -> Vector2:
    var base_pos = Vector2(col * tile_size, row * tile_size)
    
    if drag_direction.x != 0 and row == start_tile.y:
        # Horizontal drag - affect entire row
        base_pos.x += pixel_displacement.x
    elif drag_direction.y != 0 and col == start_tile.x:
        # Vertical drag - affect entire column  
        base_pos.y += pixel_displacement.y
    
    return base_pos
```

##### Visual Indicators:
- **Red Border Highlighting**: Shows which row/column is being dragged
- **Position Updates**: Real-time tile position updates during drag
- **Affected Tiles Tracking**: Efficiently identifies tiles that need position updates

### 3. Tile.gd - Individual Tile Behavior

**Primary Responsibility**: Handle tile-specific animations and visual states

#### Visual States:
```gdscript
# Hover feedback
func show_hover_feedback():
    border_rect.color = Color.WHITE
    border_rect.position = Vector2(-2, -2)
    border_rect.size = Vector2(tile_width + 4, tile_width + 4)

# Drag indicator (red border)
func show_drag_indicator():
    drag_indicator_rect.color = Color.RED
    drag_indicator_rect.position = Vector2(-3, -3)  
    drag_indicator_rect.size = Vector2(tile_width + 6, tile_width + 6)

# Connection highlighting (green tint)
func highlight_connected():
    sprite.modulate = Color(0.8, 1.2, 0.8, 1.0)  # Green tint
    connection_indicator_rect.color = Color.GREEN
    connection_indicator_rect.color.a = 0.4  # Semi-transparent
```

#### Fade Animation System:
```gdscript
var current_fade_frame: int = 0
var fade_frame_count: int = 5

func start_fade_animation():
    is_fading = true
    current_fade_frame = 0
    fade_timer.start()  # 100ms per frame
    update_fade_frame()
```

### 4. RotationHandler.gd - Array Manipulation Engine

**Primary Responsibility**: Execute row/column rotations on board data

#### Row Rotation Logic:
```gdscript
func rotate_row(row_index: int, shift_amount: int):
    # Normalize shift amount to board width
    shift_amount = (board_width + (shift_amount % board_width)) % board_width
    
    # Get current row data
    var old_row = []
    for x in board_width:
        old_row.append(board[row_index][x])
    
    # Apply rotation
    for x in board_width:
        var new_x = (x + shift_amount + board_width) % board_width
        board[row_index][new_x] = old_row[x]
        
        # Update tile grid position
        var tile = old_row[x] as Tile
        if tile:
            tile.grid_x = new_x
```

#### Column Rotation Logic:
```gdscript
func rotate_column(col_index: int, shift_amount: int):
    # Similar logic but operates on columns
    # Updates tile.grid_y instead of tile.grid_x
```

## Interactive Animation Flow

### Complete Drag Operation Sequence:

1. **Input Detection** (`Tile._on_gui_input()`)
   ```gdscript
   tile_clicked.emit(self) → GameBoard._on_tile_clicked()
   ```

2. **Drag Initialization** (`DragHandler.start_drag()`)
   ```gdscript
   drag_state = DragState.PREVIEW
   is_dragging = true
   start_tile_pos = tile_pos
   start_mouse_pos = get_viewport().get_mouse_position()
   ```

3. **Real-time Updates** (`DragHandler._input()`)
   ```gdscript
   InputEventMouseMotion → handle_mouse_move() → detect_drag_direction()
   ```

4. **Visual Feedback** (`AnimationManager.update_drag_indicators()`)
   ```gdscript
   # Highlight affected row/column
   if drag_direction.x != 0:
       highlight_row(start_tile.y, true)
   elif drag_direction.y != 0:
       highlight_column(start_tile.x, true)
   ```

5. **Position Animation** (Continuous during drag)
   ```gdscript
   GameBoard._process() → AnimationManager.apply_animated_positions()
   ```

6. **Drag Completion** (`DragHandler.handle_mouse_up()`)
   ```gdscript
   reset_drag_state() → drag_completed.emit(drag_info)
   ```

7. **Rotation Application** (`GameBoard._on_drag_completed()`)
   ```gdscript
   RotationHandler.rotate_row/column() → BoardManager.rebuild_tile_grid()
   ```

8. **Connection Detection** (`ConnectionManager.detect_and_highlight_connections()`)
   ```gdscript
   # After rotation completes, detect new connections
   ```

## Performance Optimizations

### 1. Position Caching
- **Problem**: Recalculating animated positions every frame is expensive
- **Solution**: Cache calculated positions, invalidate only when drag state changes
- **Implementation**: `animated_positions_cache` with `cache_dirty` flag

### 2. Affected Tiles Tracking  
- **Problem**: Updating all tiles when only a row/column changes
- **Solution**: `get_affected_tiles()` returns only tiles that need updates
- **Implementation**: Track only the dragged row or column

### 3. State-Based Updates
- **Problem**: Continuous processing even when not dragging
- **Solution**: State machine prevents unnecessary calculations
- **Implementation**: Check `is_dragging` flag before expensive operations

## Visual Feedback Layers

### Layer Stack (Bottom to Top):
1. **Connection Indicator** (`ColorRect`) - Green background for connected tiles
2. **Sprite** (`TextureRect`) - Main pipe graphic  
3. **Hover Border** (`ColorRect`) - White border on mouse hover
4. **Drag Indicator** (`ColorRect`) - Red border for dragged row/column

### Visual Hierarchy:
```gdscript
# Tile visual setup
connection_indicator_rect.move_to_back()  # Behind sprite
sprite.move_to_front()                    # Main graphic
border_rect.move_to_front()               # Hover feedback  
drag_indicator_rect.move_to_front()       # Drag feedback (highest priority)
```

## Animation Timing & Synchronization

### Frame-based Fade Animation:
- **Duration**: 5 frames × 100ms = 500ms total fade
- **Trigger**: Connection detection → tile removal
- **Completion**: `fade_completed` signal → batch processing for chain reactions

### Real-time Drag Animation:
- **Frequency**: Every frame during drag (`_process()`)
- **Smoothness**: Direct pixel displacement mapping
- **Responsiveness**: Sub-8px threshold for direction detection

### State Synchronization:
- **Board State**: Updated after drag completion
- **Visual State**: Updated during drag for immediate feedback  
- **Connection State**: Recalculated after each board modification

## Integration Points

### GameState Integration:
```gdscript
# Drag completion triggers move counting
GameState.use_move() → moves_changed signal → UI update

# Game over blocks further drag operations  
if GameState.lost: return  # Skip drag processing
```

### Signal-Based Communication:
```gdscript
# Primary signals
tile_clicked(tile: Tile)           # Tile → GameBoard
drag_completed(drag_state: Dict)   # DragHandler → GameBoard  
fade_completed(tile: Tile)         # Tile → ConnectionManager
connections_found(count: int)      # ConnectionManager → GameState
```

## Debug Infrastructure

### Component-Level Debugging:
```gdscript
# Each component has debug infrastructure
var debug_enabled: bool = false
func enable_debug(): debug_enabled = true
func debug_print(message: String): 
    if debug_enabled: print("[Component] ", message)
```

### State Inspection:
```gdscript
# DragHandler state inspection
func get_drag_state() -> Dictionary:
    return {
        "state": get_state_string(),
        "from": start_tile_pos,
        "to": get_target_tile_pos(),
        "pixel_displacement": pixel_displacement,
        "drag_direction": drag_direction
    }
```

This architecture provides responsive, smooth drag-and-drop functionality while maintaining clean separation of concerns and efficient performance through caching and state-based optimizations.