# GameBoard Module

## Overview
The GameBoard module is the core gameplay component of the Linkage remake, implementing a 6x8 tile-based puzzle game where players drag rows and columns to create pipe connections. Built using a component-based architecture for maintainability and separation of concerns.

## Architecture

### Component-Based Design
The GameBoard uses a modular architecture with specialized manager components:

- **GameBoard.gd** (165 lines) - Main coordinator that orchestrates all components
- **BoardManager.gd** (77 lines) - Handles board initialization and tile management
- **RotationHandler.gd** (89 lines) - Manages row/column rotation logic
- **AnimationManager.gd** (176 lines) - Controls drag animations and visual feedback
- **ConnectionManager.gd** (88 lines) - Detects connections and handles tile removal
- **DragHandler.gd** - Processes mouse input for row/column dragging
- **Tile.gd** - Individual tile behavior and fade animations
- **GameState.gd** - Global autoload singleton for game state management
- **detect.gd** - Core connection detection algorithms

## File Structure

```
gameboard/
├── scripts/
│   ├── GameBoard.gd          # Main coordinator component
│   ├── BoardManager.gd       # Board/tile management
│   ├── RotationHandler.gd    # Row/column rotation logic
│   ├── AnimationManager.gd   # Drag animations & visual feedback
│   ├── ConnectionManager.gd  # Connection detection & processing
│   ├── DragHandler.gd        # Mouse input handling
│   ├── Tile.gd               # Individual tile behavior
│   ├── GameState.gd          # Global game state (autoload)
│   └── detect.gd             # Connection detection algorithms
├── scenes/
│   ├── GameBoard.tscn        # Main gameboard scene
│   └── Tile.tscn             # Individual tile scene template
├── resources/
│   ├── pipe_sprites.tres     # Green pipe sprite resource
│   ├── green_fade_sprites.tres # Fade animation sprites
│   ├── FadeSprites.gd        # Fade animation resource script
│   └── PipeSprites.gd        # Pipe sprite resource script
└── sprites/
    └── tile_sprites/
        └── linkage_test_green2.png # Current pipe sprite asset
```

## Key Features

### Gameplay Mechanics
- **6x8 Grid**: Standard Linkage game board dimensions
- **Row/Column Dragging**: Click and drag to rotate entire rows or columns
- **Connection Detection**: Real-time detection of connected pipe segments
- **Tile Removal**: Connected tiles fade out and are removed from the board
- **Chain Reactions**: Removing tiles can trigger additional connections
- **Scoring System**: +1 point per tile removed
- **Move Tracking**: -1 move per drag operation
- **Bonus Moves**: +1 move for every 3 tiles removed in a single operation
- **Game Over**: Automatic detection when moves reach 0

### Visual Features
- **Drag Animations**: Smooth visual feedback during row/column rotation
- **Connection Highlighting**: Green highlights show connected pipe segments
- **Fade Animations**: Smooth tile removal with fade effects
- **Real-time UI Updates**: Score and moves update instantly during gameplay

## Component Details

### GameBoard.gd
Main coordinator that initializes and manages all component systems. Provides delegation methods for backward compatibility while maintaining clean separation of concerns.

### BoardManager.gd
Handles board initialization, tile creation, and grid management. Responsible for:
- Creating the initial 6x8 tile grid
- Managing tile sprites and positioning
- Providing access to board state

### RotationHandler.gd
Manages the core rotation logic for rows and columns:
- Handles array rotation operations
- Updates tile positions after rotation
- Maintains board state consistency

### AnimationManager.gd
Controls all visual animations and feedback:
- Drag animation system with smooth interpolation
- Visual indicators during drag operations
- Position caching for smooth transitions

### ConnectionManager.gd
Detects and processes pipe connections:
- Real-time connection detection using flood-fill algorithms
- Highlights connected segments in green
- Manages tile removal and fade animations
- Tracks completion for chain reactions

### GameState.gd (Autoload)
Global singleton that manages game state:
- Score tracking and updates
- Move counting and limits
- Game over detection
- Signal-based communication with UI
- Reset/restart functionality

## Integration

### Signal-Based Architecture
The GameBoard integrates with the main game through Godot's signal system:

```gdscript
# GameState signals
signal moves_changed(new_moves)
signal score_changed(new_score)  
signal game_lost()

# UI Integration
GameState.moves_changed.connect(_update_moves_display)
GameState.score_changed.connect(_update_score_display)
GameState.game_lost.connect(_show_game_over)
```

### Autoload Configuration
GameState is configured as an autoload singleton in `project.godot`:
```
[autoload]
GameState="*res://gameboard/scripts/GameState.gd"
```

## Usage

### Basic Setup
1. Add GameBoard.tscn to your scene
2. GameState autoload provides global access to game state
3. Connect to GameState signals for UI updates
4. Use GameState.reset_game() for restart functionality

### Customization
Key parameters can be adjusted in GameBoard.gd:
- `board_width`: Grid width (default: 6)
- `board_height`: Grid height (default: 8)  
- `tile_size`: Tile dimensions in pixels (default: 64)

## Development Status

### Completed Features ✅
- Complete component-based architecture
- Full gameplay loop (drag → detect → remove → score)
- Real-time UI integration via signals
- Game over detection and restart functionality
- Smooth animations and visual feedback
- Chain reaction support with bonus moves

### In Progress 🔧
- Drag animation polish and direction fixes
- Array rotation logic refinement

### Planned Features ⏳
- Load actual pipe sprites from original assets
- Sound effects integration
- Particle effects for tile removal
- Performance optimization for 60fps
- Advanced reward system with tile randomization

## Testing
The GameBoard is designed for incremental testing - each component can be tested independently, and the full game loop is functional at all times during development.