# Gameboard Implementation Plan

## Overview
Convert JavaScript gameboard to Godot 4 in runnable phases, ensuring each phase produces a working game.

## Phase 1: Basic Grid Display ✅
**Goal:** Display static 6x8 tile grid with random pipe sprites

### Implementation:
- [x] Create basic GameBoard.gd with grid generation
- [x] Create Tile.gd with colored rectangles and pipe symbols
- [x] Create simple Tile.tscn with Control node
- [x] Integrate into PlayScreen.tscn
- [x] **Runnable:** Static grid displays with colored tiles and pipe symbols

### Files Modified:
- `gameboard/scripts/GameBoard.gd` - Simplified for Phase 1
- `gameboard/scripts/Tile.gd` - ColorRect + Label display
- `gameboard/scenes/Tile.tscn` - Control-based scene
- `PlayScreen.tscn` - Added GameBoard instance

### Phase 1 Features:
- 6x8 grid of colored tiles
- Each tile shows pipe symbol (V↑, V|, V↓, H→, └, ┘, H─, ┌, ┐, H←)
- Random pipe faces (0-9) assigned to each tile
- Proper positioning within PlayScreen layout
- Debug output to console showing tile creation

## Phase 2: Input Detection ⏳
**Goal:** Click detection and visual feedback

### Implementation:
- [ ] Add Area2D click detection to tiles
- [ ] Add hover/click visual feedback
- [ ] Connect tile signals to GameBoard
- [ ] **Runnable:** Can click tiles and see feedback

### Files to Modify:
- `Tile.gd` - Add click signals
- `GameBoard.gd` - Handle tile clicks
- `Tile.tscn` - Configure Area2D properly

## Phase 3: Basic Drag Mechanics ✅
**Goal:** Row/column dragging without animation

### Implementation:
- [x] Create simplified DragHandler.gd
- [x] Implement row rotation logic
- [x] Implement column rotation logic
- [x] Add basic drag visual indicator
- [x] **Runnable:** Can drag rows/columns instantly

### Files Modified:
- `gameboard/scripts/DragHandler.gd` - Godot 4 compatible drag detection
- `GameBoard.gd` - Added drag operations and rotation methods
- `Tile.gd` - Added drag indicator visuals

## Phase 4: Connection Detection ⏳
**Goal:** Detect and highlight pipe connections

### Implementation:
- [ ] Create simplified detect.gd
- [ ] Implement basic pipe connection rules
- [ ] Add visual highlighting for connected tiles
- [ ] **Runnable:** See connected pipes highlighted

### Files to Add/Modify:
- `gameboard/scripts/detect.gd` - Core algorithm
- `GameBoard.gd` - Call detection after moves
- `Tile.gd` - Add highlight state

## Phase 5: Tile Removal ⏳
**Goal:** Remove connected tiles and replace

### Implementation:
- [ ] Add tile removal animation
- [ ] Implement tile replacement logic
- [ ] Add basic scoring system
- [ ] **Runnable:** Connected tiles disappear and are replaced

### Files to Modify:
- `detect.gd` - Add removal logic
- `GameBoard.gd` - Handle tile replacement
- `Tile.gd` - Add removal animation

## Phase 6: Game State Integration ⏳
**Goal:** Full game mechanics with moves and scoring

### Implementation:
- [ ] Create GameState.gd singleton
- [ ] Add move counter
- [ ] Add score display
- [ ] Add game over detection
- [ ] **Runnable:** Complete playable game

### Files to Add/Modify:
- `gameboard/scripts/GameState.gd` - Full implementation
- `GameBoard.gd` - Connect to game state
- `PlayScreen.gd` - Display moves/score

## Phase 7: Polish & Integration ⏳
**Goal:** Smooth animations and full feature parity

### Implementation:
- [ ] Add smooth drag animations
- [ ] Implement reward system
- [ ] Add sound effects
- [ ] Load actual sprite assets
- [ ] **Runnable:** Full-featured game matching original

### Files to Modify:
- All scripts - Add animations and polish
- Load sprites from `linkage/imgs/tile_spr/`

---

## Quick Start Commands

### Phase 1 Setup:
```bash
# Run from project root
godot --path . res://PlayScreen.tscn
```

### Testing Each Phase:
- Each phase should be immediately runnable
- Test by opening PlayScreen.tscn in Godot
- Verify functionality before proceeding to next phase

## Critical Success Criteria:
✅ **Phase 1:** Grid displays  
✅ **Phase 2:** Tiles respond to clicks  
✅ **Phase 3:** Rows/columns can be dragged  
⏳ **Phase 4:** Connections are detected visually  
⏳ **Phase 5:** Connected tiles are removed  
⏳ **Phase 6:** Full game loop works  
⏳ **Phase 7:** Matches original experience