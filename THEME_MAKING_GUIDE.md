# Theme Making Guide for Linkage Remake

## Current Theme Analysis
Based on the codebase, you're currently using a **green pipe theme** with a sprite sheet approach.

## Key Theme Components You Should Create

### 1. Pipe Sprite Sheet (MOST IMPORTANT)
**What to make:** Single sprite sheet image containing all 15 pipe types
- **Current setup:** 3 columns × 4 rows = 12 sprites (needs expansion to 5 rows for 15 sprites)
- **File:** `linkage_test_green2.png` (replace this file)
- **Size:** 192×320 pixels (64×64 per sprite, 3 columns × 5 rows)
- **Layout:**
  ```
  [0-straight-H] [1-straight-V] [2-L-topleft]
  [3-L-topright] [4-L-botright] [5-L-botleft]
  [6-T-top]      [7-T-right]   [8-T-bottom]
  [9-T-left]     [10-4way]     [11-end-right]
  [12-end-left]  [13-end-up]   [14-end-down]
  ```

### 2. Theme Elements to Design

#### Core Visual Style Choices:
1. **Pipe Material Theme:**
   - Metal pipes (industrial/steampunk)
   - Neon/cyber pipes (futuristic)
   - Water/plumbing pipes (realistic)
   - Fantasy tubes (magical energy)
   - Circuit traces (electronic)

2. **Color Schemes:**
   - **Current:** Green pipes
   - **Alternatives:** Blue, Orange, Purple, Multi-color
   - **Consider:** Color-blind accessibility

3. **Visual Details:**
   - **Pipe thickness:** Thin lines vs thick tubes
   - **Surface texture:** Smooth, metallic, glowing, rough
   - **Connection points:** How pipes join together
   - **Pipe interiors:** Hollow, filled, flowing energy

### 3. Connection Highlight System
**What to make:** Visual feedback for connected pipes
- **Current:** Green highlighting overlay
- **Theme options:**
  - Glowing edges around connected pipes
  - Flowing animation inside pipes
  - Pulsing brightness
  - Color change of the pipes themselves

### 4. Background/Board Theme
**Consider these elements:**
- **Grid background:** Subtle pattern or solid color
- **Board frame:** Industrial panel, wooden frame, high-tech display
- **Ambient elements:** Steam, sparks, flowing particles

## Technical Constraints

### Sprite Sheet Requirements:
- **Tile size:** 64×64 pixels per pipe
- **Format:** PNG with transparency
- **Grid alignment:** Must align perfectly in 3×5 grid
- **Connection points:** Pipes must visually connect at tile edges

### Current Code Integration:
- Sprites loaded via `pipe_sprites.tres` resource
- Sheet parsed by `PipeSprites.gd` script
- Grid system expects 3 columns, currently 4 rows (needs 5 rows)

## Recommended Theme Approaches

### Option 1: Industrial/Steampunk
- Metallic copper/bronze pipes
- Rivets and joints at connections
- Steam particle effects
- Dark industrial background

### Option 2: Neon/Cyber
- Glowing colored pipes
- Circuit board background
- Electric particle effects
- High contrast colors

### Option 3: Water/Plumbing (Realistic)
- Blue/gray PVC or metal pipes
- Water flow animations
- Tile background like bathroom/kitchen
- Realistic pipe fittings

## What You Should Focus On:

1. **PRIMARY:** Create the 192×320 sprite sheet with all 15 pipe types
2. **SECONDARY:** Design connection highlight effect
3. **TERTIARY:** Background/board styling

## Visual Consistency Tips:
- Keep pipe opening sizes consistent for connections
- Use same line thickness throughout
- Maintain consistent lighting direction
- Test readability on different screen sizes
- Consider how highlighted/selected pipes will look