# Complete Gameboard Implementation Plan

## Overview
Convert JavaScript HTML5 Canvas gameboard to Godot 4 in 7 runnable phases. Each phase produces a working game that can be tested immediately.

---

## Phase 1: Basic Grid Display ✅ COMPLETED
**Goal:** Static 6x8 tile grid with colored pipe symbols

### What Works:
- 6x8 grid displays in PlayScreen
- Each tile shows colored rectangle + pipe symbol
- Random pipe faces (0-9): V↑, V|, V↓, H→, └, ┘, H─, ┌, ┐, H←
- Debug console output

### Files:
- `GameBoard.gd` - Basic grid generation
- `Tile.gd` - ColorRect + Label display
- `Tile.tscn` - Control node scene
- `PlayScreen.tscn` - Integrated GameBoard

**Test:** Open PlayScreen.tscn → See colored grid

---

## Phase 2: Input Detection ✅ COMPLETED
**Goal:** Click tiles and see visual feedback

### Implementation Tasks:
- [x] Add Area2D + CollisionShape2D to Tile.tscn
- [x] Add `tile_clicked` signal to Tile.gd
- [x] Add hover/click visual feedback (border highlight)
- [x] Connect signals to GameBoard._on_tile_clicked()
- [x] Add console output for clicked coordinates

### Files to Modify:
- `Tile.tscn` - Add Area2D child nodes
- `Tile.gd` - Add input_event handler + visual feedback
- `GameBoard.gd` - Add click handler method

### Success Criteria:
✅ Tiles respond to mouse clicks  
✅ Visual feedback on hover/click  
✅ Console shows clicked tile (x,y)  

**Test:** Click tiles → See border highlight + console output

---

## Phase 3: Basic Drag Mechanics ✅ COMPLETED
**Goal:** Drag rows/columns without smooth animation

### Implementation Tasks:
- [x] Create simplified DragHandler.gd (no smooth movement)
- [x] Add mouse_down → detect drag start
- [x] Add mouse_move → determine row/column drag
- [x] Add mouse_up → apply rotation instantly
- [x] Implement array rotation for rows/columns
- [x] Add red border on dragged row/column

### Files Modified:
- `DragHandler.gd` - Basic drag detection (Godot 4 compatible)
- `GameBoard.gd` - Added rotation methods and drag integration
- `Tile.gd` - Added drag indicator methods

### Success Criteria:
✅ Click+drag rotates entire row/column  
✅ Tiles jump to new positions instantly  
✅ Visual indicator shows active drag (red borders)
✅ All 6 rows and 8 columns respond to drag
✅ Proper Godot 4 event handling (no HTML5 legacy code)

**Test:** Drag rows/columns → Tiles rearrange immediately

---

## Phase 4: Connection Detection ✅ COMPLETED
**Goal:** Highlight connected pipe networks

### Implementation Tasks:
- [x] Create simplified detect.gd with LinkDetector class
- [x] Implement pipe connection rules (10 types)
- [x] Add connection detection after each move
- [x] Highlight connected tiles (green background + sprite tint)
- [x] Implement recursive connection tracking algorithm

### Files Added/Modified:
- `detect.gd` - Full LinkDetector implementation with connection algorithm
- `GameBoard.gd` - Calls detection after moves, handles highlighting
- `Tile.gd` - Added highlight_connected() and hide_connected_highlight() methods

### Success Criteria:
✅ Connected pipes show green highlight and sprite tint
✅ Detection runs after each drag operation
✅ All 10 pipe types connect correctly
✅ Recursive algorithm handles complex pipe networks

**Test:** Create pipe connections → See green highlights + sprite tints

---

## Phase 5: Tile Removal ✅ COMPLETED
**Goal:** Remove connected tiles and replace with new ones

### Implementation Tasks:
- [x] Add tile removal animation (fade out)
- [x] Replace removed tiles with random new faces
- [x] Add basic scoring (+1 per removed tile)
- [x] Add chain reaction detection
- [x] Update moves counter
- [x] Integrate with GameState singleton

### Files to Modify:
- `detect.gd` - Add removal + replacement logic (remove_links method exists)
- `GameBoard.gd` - Handle tile animations and integrate removal
- `Tile.gd` - Add fade animation
- `GameState.gd` - Basic score/moves tracking (already implemented)

### Success Criteria:
✅ Connected tiles fade and disappear  
✅ New random tiles appear  
✅ Score increases  
✅ Chain reactions work  

**Test:** Create connections → Tiles disappear → New tiles appear

---

## Phase 6: Game State Integration ✅ COMPLETED
**Goal:** Complete game loop with moves/scoring/game over

### Implementation Tasks:
- [x] Create GameState.gd singleton
- [x] Add moves counter (starts at 100)
- [x] Add score display in PlayScreen
- [x] Add game over detection (moves = 0)
- [x] Add restart functionality
- [x] Connect UI buttons to game state

### Files to Add/Modify:
- `GameState.gd` - Full singleton implementation
- `GameBoard.gd` - Connect to game state
- `PlayScreen.gd` - Update UI displays
- `project.godot` - Add GameState autoload

### Success Criteria:
✅ Moves decrease with each drag  
✅ Score updates in real-time  
✅ Game over dialog appears  
✅ Restart button works  

**Test:** Play until moves = 0 → Game over → Restart works

---

## Phase 7: Polish & Features ⏳ NEXT
**Goal:** Smooth animations and full feature parity

### Implementation Tasks:
- [ ] Add smooth drag animations with Tween nodes
- [ ] Load actual pipe sprite assets from linkage/imgs/
- [ ] Add sound effects (click, drag, tile removal, game over)
- [ ] Implement reward system integration (randomize tiles via GameState)
- [ ] Add particle effects for tile removal animations
- [ ] Optimize performance for smooth 60fps gameplay
- [ ] Add visual polish (better fade effects, connection highlights)
- [ ] Implement proper tile randomization for reward system

### Files to Add/Modify:
- `GameBoard.gd` - Add Tween nodes for smooth drag animations
- `Tile.gd` - Enhanced visual effects and sprite loading
- `resources/` - Load proper pipe sprites from linkage/imgs/
- `GameState.gd` - Connect reward system to tile randomization
- `PlayScreen.gd` - Add sound effect integration
- Add AudioStreamPlayer nodes to scenes

### Success Criteria:
✅ Smooth drag animations with visual feedback
✅ Proper pipe sprites from original assets
✅ Sound effects for all game interactions
✅ Reward system fully functional
✅ 60fps performance maintained
✅ Visual polish matches or exceeds original game

**Test:** Full gameplay experience matches original with smooth animations

---

## File Structure (Final)
```
gameboard/
├── scripts/
│   ├── GameBoard.gd          # Main controller
│   ├── Tile.gd               # Individual tile logic  
│   ├── DragHandler.gd        # Input management
│   ├── GameState.gd          # Global state singleton
│   └── detect.gd             # Connection algorithms
├── scenes/
│   ├── GameBoard.tscn        # Main board scene
│   └── Tile.tscn             # Tile scene
├── resources/
│   └── tile_sprites/         # Sprite assets
├── COMPLETE_IMPLEMENTATION_PLAN.md  # This file
├── IMPLEMENTATION.md         # Detailed phase docs
├── PHASE2_CHECKLIST.md       # Current phase tasks
└── README.md                 # Component documentation
```

---

## Testing Strategy

### Each Phase Must Be Runnable:
1. **Open** `PlayScreen.tscn` in Godot 4
2. **Run** current scene (F6)
3. **Test** current phase functionality
4. **Verify** no errors in debug console
5. **Proceed** to next phase only if current works

### Debug Commands:
```gdscript
# Add to GameBoard.gd for debugging
print("Phase X: Feature working")
print("Tile clicked at: ", tile_pos)
print("Drag completed: ", from, " to ", to)
```

---

## Integration Points

### With Existing Code:
- **PlayScreen.tscn** - GameBoard fits in GameArea
- **Button handlers** - Connect to GameState methods
- **Asset loading** - Use existing sprites in linkage/imgs/
- **Sound system** - Integrate with existing audio

### Android Integration:
- **GameState.gd** exposes window.restart, window.reward
- **Score reporting** via Android interface
- **Reward ads** trigger tile randomization

---

## Success Metrics

### Phase Completion Criteria:
- ✅ **Runnable** - No crashes or errors
- ✅ **Functional** - Core feature works as designed  
- ✅ **Testable** - User can interact and see results
- ✅ **Progressive** - Builds on previous phases

### Final Success:
- ✅ **Feature Parity** - Matches original JavaScript game
- ✅ **Performance** - Smooth 60fps gameplay
- ✅ **Integration** - Works with existing screens
- ✅ **Maintainable** - Clean, documented code

---

## Current Status: Phase 6 Complete ✅
**Next Action:** Review this plan → Proceed with Phase 7 implementation

### Phase Progress:
- ✅ **Phase 1:** Basic Grid Display - Static 6x8 tile grid with colored pipe symbols
- ✅ **Phase 2:** Input Detection - Tiles respond to mouse clicks with visual feedback  
- ✅ **Phase 3:** Basic Drag Mechanics - Row/column dragging with instant rotation
- ✅ **Phase 4:** Connection Detection - Pipes connect and highlight properly
- ✅ **Phase 5:** Tile Removal - Fade animations, scoring, chain reactions complete
- ✅ **Phase 6:** Game State Integration - UI updates, game over detection, full game loop
- ⏳ **Phase 7:** Polish & Features - NEXT PHASE
