# Phase 2: Input Detection - Implementation Checklist

## Goal: Click detection and visual feedback

### Tasks:
- [ ] Add Area2D input detection to Tile.tscn
- [ ] Implement tile_clicked signal in Tile.gd  
- [ ] Add hover visual feedback (border highlight)
- [ ] Connect tile signals to GameBoard.gd
- [ ] Add click sound effect (optional)
- [ ] Test: Click tiles and see visual feedback

### Files to Modify:
1. **Tile.tscn** - Add Area2D + CollisionShape2D child nodes
2. **Tile.gd** - Add input handling and visual feedback
3. **GameBoard.gd** - Add _on_tile_clicked handler

### Success Criteria:
✅ Tiles respond to mouse clicks  
✅ Visual feedback on hover/click  
✅ Console output shows clicked tile coordinates  
✅ No errors in debug console  

### Next: Phase 3 - Basic Drag Mechanics
