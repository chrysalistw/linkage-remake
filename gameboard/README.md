# Gameboard Mechanics

This folder contains the core gameboard mechanics for the Linkage puzzle game, converted from the JavaScript implementation to Godot 4.

## Structure

```
gameboard/
├── scripts/
│   ├── GameBoard.gd          # Main gameboard controller
│   ├── Tile.gd               # Individual tile logic with pipe connections
│   ├── DragHandler.gd        # Input and drag mechanics for row/column manipulation
│   ├── GameState.gd          # Global game state singleton
│   └── detect.gd             # Connection detection algorithms
├── scenes/
│   ├── GameBoard.tscn        # Main gameboard scene
│   └── Tile.tscn             # Individual tile scene with Area2D
└── resources/
	└── tile_sprites/         # Placeholder for tile sprite resources
```

## Key Components

### GameBoard.gd
- Main controller managing the 6x8 tile grid
- Handles board initialization, tile creation, and drag operations
- Manages row/column rotation mechanics
- Coordinates link detection and removal

### Tile.gd
- Individual tile representation with pipe type (faces 0-9)
- Area2D-based input detection
- Connection logic for 10 different pipe configurations
- Animation support for normal and fading states

### DragHandler.gd
- Processes mouse/touch input for tile dragging
- Supports horizontal and vertical row/column dragging
- Provides visual feedback during drag operations
- Calculates temporary positions for smooth previews

### GameState.gd
- Singleton managing global game state (moves, score, game over)
- Android WebView integration callbacks
- Sound system and asset management
- Reward system support

### detect.gd
- Port-based connection detection algorithm
- Recursive link tracking with loop detection
- Automated tile removal and replacement
- Scoring and bonus move calculation

## Integration

To integrate with existing screens:
1. Add GameBoard scene as child of PlayScreen
2. Configure GameState as autoload singleton
3. Connect gameboard signals to UI elements
4. Load tile sprite resources into Tile scenes

## Based On

This implementation follows the pseudocode specifications in `/pseudocode/` and maintains compatibility with the original JavaScript mechanics while leveraging Godot 4's scene system and built-in input handling.
