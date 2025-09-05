# How to Create a New Theme

This guide shows the exact files and steps needed to add a new theme to the Linkage Remake game.

## Step-by-Step Instructions

### Step 1: Create Theme Folder
Create a new folder for your theme:
```
themes/your_theme_name/
```
Replace `your_theme_name` with your theme's ID (use lowercase, underscores for spaces).

### Step 2: Create Theme Config File
Create `themes/your_theme_name/theme_config.json`:
```json
{
  "name": "Your Theme Display Name",
  "title_path": null,
  "tileset_path": "res://gameboard/resources/your_tileset.tres",
  "bg_pattern_path": null,
  "theme_path": "res://theme/your_theme.tres",
  "background_color": "#HEXCOLOR",
  "preview_face": 4
}
```

**Field explanations:**
- `name`: Display name shown in theme selector
- `tileset_path`: Path to your pipe sprites resource file
- `theme_path`: Path to your UI theme resource file
- `background_color`: Hex color for game background
- `preview_face`: Which pipe sprite to show in theme preview (0-14)

### Step 3: Create Sprite Sheet
Create a pipe sprite sheet image with these specifications:
- **Size:** 192×320 pixels
- **Format:** PNG with transparency
- **Layout:** 3 columns × 5 rows = 15 pipe sprites
- **Sprite size:** 64×64 pixels each
- **Pipe arrangement:**
  ```
  [0-straight-H] [1-straight-V] [2-L-topleft]
  [3-L-topright] [4-L-botright] [5-L-botleft]
  [6-T-top]      [7-T-right]   [8-T-bottom]
  [9-T-left]     [10-4way]     [11-end-right]
  [12-end-left]  [13-end-up]   [14-end-down]
  ```

### Step 4: Create Tileset Resource
1. In Godot, create a new `SpriteFrames` resource
2. Import your sprite sheet image
3. Configure it to slice into 3×5 grid of 64×64 sprites
4. Save as `gameboard/resources/your_tileset.tres`

### Step 5: Create UI Theme Resource
1. In Godot, create a new `Theme` resource
2. Configure colors, fonts, and UI styling to match your theme
3. Save as `theme/your_theme.tres`

### Step 6: Register Theme
Add your theme to `themes/theme_registry.json` in the `themes` array:
```json
{
  "id": "your_theme_name",
  "config_file": "themes/your_theme_name/theme_config.json",
  "enabled": true,
  "unlock_condition": "default",
  "display_order": 3
}
```

**Field explanations:**
- `id`: Must match your theme folder name
- `config_file`: Path to your theme config
- `enabled`: Set to `true` to make theme available
- `unlock_condition`: Use `"default"` for always unlocked
- `display_order`: Position in theme selector (higher = later)

## File Checklist

For a new theme called `purple_cyber`, you need:

- [ ] `themes/purple_cyber/` (folder)
- [ ] `themes/purple_cyber/theme_config.json` (config file)
- [ ] `purple_cyber_pipes.png` (sprite sheet image)
- [ ] `gameboard/resources/purple_cyber_tileset.tres` (Godot resource)
- [ ] `theme/purple_cyber_theme.tres` (Godot UI theme)
- [ ] Update `themes/theme_registry.json` (add theme entry)

## Visual Design Guidelines

### Sprite Sheet Requirements
- All pipes must connect properly at tile edges
- Use consistent line thickness throughout
- Maintain same lighting direction for all sprites
- Ensure readability at small sizes
- Consider color-blind accessibility

### Theme Consistency
- Choose a cohesive color palette
- Design connection highlights that complement pipes
- Test background color contrast with pipes
- Ensure UI theme colors work well together

## Testing Your Theme

1. Launch the game
2. Go to theme selection screen
3. Verify your theme appears in the list
4. Select your theme and test:
   - All pipe types display correctly
   - Connections highlight properly
   - Background color looks good
   - UI elements are readable

## Common Issues

- **Theme not appearing:** Check `theme_registry.json` syntax
- **Pipes look wrong:** Verify sprite sheet dimensions (192×320)
- **Connection problems:** Ensure pipe openings align at tile edges
- **UI looks bad:** Adjust colors in your UI theme resource