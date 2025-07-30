# Godot Drag Animation Implementation Plan

## Analysis of Original Linkage Drag System

### Key Components Analyzed

1. **playDragHandler.js**: Core drag logic and displacement calculations
2. **mainGameNode.js**: Rendering system with real-time tile displacement
3. **Tile.js**: Basic tile positioning and bounds management
4. **lib.js**: Array rotation utilities for row/column manipulation

### Original Animation Mechanics

#### Drag State Management
- **States**: `undefined` → `horizontal` | `vertical`
- **Direction Detection**: Based on mouse movement (`movementX` vs `movementY`)
- **Displacement Calculation**: 
  ```javascript
  let l = Math.sqrt(l2)%w/w  // Distance modulo tile width
  dh.displace = {x: l*dir.x*w/10, y: l*dir.y*w/10}  // Scaled displacement
  ```

#### Real-time Visual Displacement
```javascript
// In mainGameNode.js draw function
switch (state){
	case "horizontal":
		if(y==from.row) nx += displace.x  // Shift entire row
		break
	case "vertical": 
		if(x==from.col) ny += displace.y  // Shift entire column
		break
	case undefined:
		// Preview mode - shift in detected direction
		if(dir?.x==0 && x==from.col) ny += displace.y
		if(dir?.y==0 && y==from.row) nx += displace.x
		break
}
```

#### Tile Position Prediction
```javascript
function temp_positions(game, x, y){
	if(playDragHandler.to && playDragHandler.state == "vertical")
		if(playDragHandler.from.col==x){
			y += playDragHandler.to.row-playDragHandler.from.row
			y = (y+game.height)%game.height  // Wrap around
		}
	// Similar for horizontal...
}
```

## Godot Implementation Strategy

### Phase 1: Core Animation System

#### 1.1 Enhance DragHandler.gd
```gdscript
# Add animation state tracking
enum DragState { NONE, PREVIEW, HORIZONTAL, VERTICAL }
var drag_state: DragState = DragState.NONE
var displacement: Vector2 = Vector2.ZERO
var drag_direction: Vector2 = Vector2.ZERO
var start_position: Vector2
var current_displacement_factor: float = 0.0

# Displacement calculation (matching original logic)
func calculate_displacement(current_pos: Vector2) -> Vector2:
	var distance = start_position.distance_to(current_pos)
	var tile_size = gameboard.tile_size
	var normalized_distance = fmod(distance, tile_size) / tile_size
	return drag_direction * normalized_distance * tile_size * 0.1
```

#### 1.2 Real-time Tile Position Updates
```gdscript
# In GameBoard.gd - add animation positioning
func get_animated_tile_position(row: int, col: int) -> Vector2:
	var base_pos = Vector2(col * tile_size, row * tile_size)
	
	if drag_handler.drag_state == DragHandler.DragState.NONE:
		return base_pos
	
	var from_tile = drag_handler.from_tile
	var displacement = drag_handler.displacement
	
	match drag_handler.drag_state:
		DragHandler.DragState.HORIZONTAL:
			if row == from_tile.y:
				base_pos.x += displacement.x
		DragHandler.DragState.VERTICAL:
			if col == from_tile.x:
				base_pos.y += displacement.y
		DragHandler.DragState.PREVIEW:
			# Show preview in detected direction
			if drag_handler.drag_direction.x == 0 and col == from_tile.x:
				base_pos.y += displacement.y
			elif drag_handler.drag_direction.y == 0 and row == from_tile.y:
				base_pos.x += displacement.x
	
	return base_pos
```

### Phase 2: Tile Wrapping Animation

#### 2.1 Predict Tile Positions During Drag
```gdscript
# In GameBoard.gd
func get_predicted_tile_position(row: int, col: int) -> Vector2i:
	if not drag_handler.is_dragging:
		return Vector2i(col, row)
	
	var from_pos = drag_handler.from_tile
	var to_pos = drag_handler.to_tile
	
	if not to_pos or drag_handler.drag_state == DragHandler.DragState.PREVIEW:
		return Vector2i(col, row)
	
	var predicted_row = row
	var predicted_col = col
	
	match drag_handler.drag_state:
		DragHandler.DragState.VERTICAL:
			if col == from_pos.x:
				var shift = to_pos.y - from_pos.y
				predicted_row = (row + shift + ROWS) % ROWS
		DragHandler.DragState.HORIZONTAL:
			if row == from_pos.y:
				var shift = to_pos.x - from_pos.x
				predicted_col = (col + shift + COLS) % COLS
	
	return Vector2i(predicted_col, predicted_row)
```

#### 2.2 Render Tiles at Predicted Positions
```gdscript
# In Tile.gd - update draw function
func _draw():
	if not gameboard:
		return
	
	# Get both animated position and predicted grid position
	var animated_pos = gameboard.get_animated_tile_position(grid_row, grid_col)
	var predicted_grid = gameboard.get_predicted_tile_position(grid_row, grid_col)
	
	# Draw tile at animated position with predicted face
	var predicted_face = gameboard.tiles[predicted_grid.y][predicted_grid.x].face
	draw_tile_sprite(predicted_face, animated_pos)
```

### Phase 3: Visual Polish

#### 3.1 Drag Visual Feedback
```gdscript
# In GameBoard.gd - add drag indicators
func _draw():
	if drag_handler.is_dragging and drag_handler.from_tile:
		# Red outline on dragged tile
		var from_pos = get_animated_tile_position(drag_handler.from_tile.y, drag_handler.from_tile.x)
		draw_rect(Rect2(from_pos, Vector2(tile_size, tile_size)), Color.RED, false, 4.0)
		
		# Drag direction indicator
		if drag_handler.displacement.length() > 0:
			var start_center = from_pos + Vector2(tile_size/2, tile_size/2)
			var end_center = start_center + drag_handler.displacement
			draw_line(start_center, end_center, Color.RED, 5.0)
```

#### 3.2 Smooth State Transitions
```gdscript
# In DragHandler.gd - add state transition smoothing
var transition_tween: Tween

func _ready():
	transition_tween = Tween.new()
	add_child(transition_tween)

func reset_displacement():
	# Smooth return to original positions
	transition_tween.tween_property(self, "displacement", Vector2.ZERO, 0.2)
	transition_tween.tween_callback(func(): drag_state = DragState.NONE)
```

### Phase 4: Performance Optimization

#### 4.1 Efficient Position Caching
```gdscript
# Cache animated positions to avoid recalculation
var animated_positions_cache: Dictionary = {}
var cache_dirty: bool = true

func invalidate_position_cache():
	cache_dirty = true

func get_cached_animated_position(row: int, col: int) -> Vector2:
	if cache_dirty:
		rebuild_position_cache()
	return animated_positions_cache.get(Vector2i(col, row), Vector2.ZERO)
```

#### 4.2 Selective Tile Updates
```gdscript
# Only update tiles affected by current drag operation
func get_affected_tiles() -> Array[Vector2i]:
	if not drag_handler.is_dragging:
		return []
	
	var affected = []
	var from_tile = drag_handler.from_tile
	
	match drag_handler.drag_state:
		DragHandler.DragState.HORIZONTAL, DragHandler.DragState.PREVIEW:
			# Entire row
			for col in range(COLS):
				affected.append(Vector2i(col, from_tile.y))
		DragHandler.DragState.VERTICAL:
			# Entire column  
			for row in range(ROWS):
				affected.append(Vector2i(from_tile.x, row))
	
	return affected
```

## Implementation Timeline

### Week 1: Core Animation Framework
- [ ] Enhance DragHandler.gd with displacement calculations
- [ ] Add get_animated_tile_position() to GameBoard.gd
- [ ] Implement basic real-time tile shifting

### Week 2: Tile Wrapping & Prediction
- [ ] Add get_predicted_tile_position() logic
- [ ] Implement tile face prediction during drag
- [ ] Test wrapping behavior at grid edges

### Week 3: Visual Polish & Feedback  
- [ ] Add drag indicators (red outline, direction line)
- [ ] Implement smooth state transitions with Tween
- [ ] Add preview mode for direction detection

### Week 4: Performance & Testing
- [ ] Implement position caching system
- [ ] Add selective tile updates
- [ ] Performance testing and optimization
- [ ] Integration testing with existing Phase 6 features

## Technical Notes

### Key Differences from Original
1. **Godot Coordinate System**: Y-axis flipped compared to canvas
2. **Node-based Architecture**: Each tile is a separate node vs single canvas
3. **Built-in Animation**: Tween nodes vs manual interpolation
4. **Signal System**: Real-time updates via signals vs direct property access

### Integration Points
- Must maintain compatibility with existing GameState singleton
- Preserve Phase 6 score/moves tracking during animations  
- Ensure connection detection works during drag animations
- Maintain tile fade animations from Phase 5

### Success Criteria
1. Smooth real-time tile displacement during drag
2. Accurate tile wrapping at grid boundaries
3. Visual feedback matching original game feel
4. 60fps performance on target Android devices
5. No regression in existing Phase 1-6 functionality
