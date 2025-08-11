# Image Assets Needed for Linkage Remake

## Current Asset Status
Based on CLAUDE.md, the game currently uses basic pipe sprites but needs proper visual assets for a polished experience.

## Required Image Assets

### 1. Pipe Tile Sprites (Primary Game Assets)
**Location to prepare:** `linkage/imgs/` directory
- **pipe_0.png** - Straight horizontal pipe
- **pipe_1.png** - Straight vertical pipe  
- **pipe_2.png** - L-shaped pipe (top-left corner)
- **pipe_3.png** - L-shaped pipe (top-right corner)
- **pipe_4.png** - L-shaped pipe (bottom-right corner)
- **pipe_5.png** - L-shaped pipe (bottom-left corner)
- **pipe_6.png** - T-junction pipe (top connection)
- **pipe_7.png** - T-junction pipe (right connection)
- **pipe_8.png** - T-junction pipe (bottom connection)
- **pipe_9.png** - T-junction pipe (left connection)
- **pipe_10.png** - 4-way cross pipe
- **pipe_11.png** - End cap pipe (right)
- **pipe_12.png** - End cap pipe (left)
- **pipe_13.png** - End cap pipe (up)
- **pipe_14.png** - End cap pipe (down)

**Specifications:**
- Size: 64x64 pixels recommended
- Format: PNG with transparency
- Style: Match game's visual theme
- Clear pipe connections visible

### 2. UI Button Assets
- **reset_button.png** - Reset game button
- **restart_button.png** - Restart button
- **reset_button_pressed.png** - Pressed state
- **restart_button_pressed.png** - Pressed state

### 3. Game State Visual Feedback
- **connection_highlight.png** - Green glow/outline for connected pipes
- **drag_arrow.png** - Direction indicator for row/column dragging
- **tile_selector.png** - Selection highlight for active tile

### 4. Particle Effects (Optional Polish)
- **pipe_connect_particle.png** - Small effect when pipes connect
- **tile_remove_particle.png** - Effect when tiles fade out
- **bonus_particle.png** - Effect for bonus moves earned

### 5. Background/UI Elements
- **game_background.png** - Game board background
- **score_panel.png** - UI panel background
- **game_over_dialog_bg.png** - Game over dialog background

## Asset Preparation Notes

### Current Issues to Address:
1. **Fade Animation Sprites** - Current pipe sprites need fade animation versions
2. **Visual Click Feedback** - Need clearer indication when tiles are clickable/dragged
3. **Connection Highlights** - Current green highlighting could be improved

### Technical Requirements:
- All sprites should be 64x64 pixels for consistency
- PNG format with proper transparency
- Consider 2x versions for high-DPI displays
- Maintain consistent art style across all assets

### Priority Order:
1. **High Priority:** Pipe tile sprites (0-14) - Core gameplay visuals
2. **Medium Priority:** Connection highlights and drag feedback
3. **Low Priority:** Particle effects and background polish

## Integration Notes
- Assets will be loaded through Godot's resource system
- Sprites are referenced in `pipe_sprites.tres` and related resources
- Fade animations use separate sprite resources in `green_fade_sprites.tres`