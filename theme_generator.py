#!/usr/bin/env python3
"""
Godot Theme Generator
Generates theme .tres and animation .tres files from color palette JSON.

Usage:
    python theme_generator.py input_palette.json theme_name output_dir

Example:
    python theme_generator.py default_green.json "Default Green" themes/default_green
"""

import json
import sys
import os
from datetime import datetime

def hex_to_godot_color(hex_color):
    """Convert hex color to Godot Color format (0.0-1.0 RGB values)"""
    hex_color = hex_color.lstrip('#')
    r = int(hex_color[0:2], 16) / 255.0
    g = int(hex_color[2:4], 16) / 255.0
    b = int(hex_color[4:6], 16) / 255.0
    return f"Color({r:.3f}, {g:.3f}, {b:.3f}, 1)"

def generate_theme_tres(palette, theme_name):
    """Generate the theme .tres file content from color palette"""
    
    # Convert colors
    primary_color = hex_to_godot_color(palette['tilesetPrimary'])
    outline_color = hex_to_godot_color(palette['tilesetOutline'])
    panel_color = hex_to_godot_color(palette['displayPanelColor'])
    panel_outline = hex_to_godot_color(palette['displayPanelOutline'])
    dialog_bg = hex_to_godot_color(palette['dialogPanelColor'])
    dialog_outline = hex_to_godot_color(palette['dialogPanelOutline'])
    text_color = hex_to_godot_color(palette['textColor'])
    
    return f"""[gd_resource type="Theme" load_steps=6 format=3]

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_dialog"]
bg_color = {dialog_bg}
border_width_left = 3
border_width_top = 3
border_width_right = 3
border_width_bottom = 3
border_color = {dialog_outline}
corner_radius_top_left = 16
corner_radius_top_right = 16
corner_radius_bottom_right = 16
corner_radius_bottom_left = 16

[sub_resource type="StyleBoxEmpty" id="StyleBoxEmpty_ag65a"]

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_button_normal"]
bg_color = {primary_color}
border_width_bottom = 8
border_color = {outline_color}
corner_radius_top_left = 30
corner_radius_top_right = 30
corner_radius_bottom_right = 30
corner_radius_bottom_left = 30

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_button_pressed"]
content_margin_left = 2.0
content_margin_top = 4.0
content_margin_right = 2.0
content_margin_bottom = 0.0
bg_color = {primary_color}
border_width_top = 8
border_color = {outline_color}
corner_radius_top_left = 30
corner_radius_top_right = 30
corner_radius_bottom_right = 30
corner_radius_bottom_left = 30

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_panel"]
bg_color = {panel_color}
border_width_bottom = 10
border_color = {panel_outline}
corner_radius_top_left = 12
corner_radius_top_right = 12
corner_radius_bottom_right = 12
corner_radius_bottom_left = 12

[resource]
default_font_size = 33
AcceptDialog/colors/title_color = {primary_color}
AcceptDialog/font_sizes/title_font_size = 54
AcceptDialog/styles/panel = SubResource("StyleBoxFlat_dialog")
Button/colors/font_color = {text_color}
Button/colors/font_hover_color = {text_color}
Button/colors/font_pressed_color = {text_color}
Button/font_sizes/font_size = 42
Button/styles/focus = SubResource("StyleBoxEmpty_ag65a")
Button/styles/hover = SubResource("StyleBoxFlat_button_normal")
Button/styles/normal = SubResource("StyleBoxFlat_button_normal")
Button/styles/pressed = SubResource("StyleBoxFlat_button_pressed")
Label/colors/font_color = {text_color}
Label/constants/shadow_offset_x = 2
Label/constants/shadow_offset_y = 2
Label/font_sizes/font_size = 33
Panel/styles/panel = SubResource("StyleBoxFlat_panel")
PopupPanel/styles/panel = SubResource("StyleBoxFlat_dialog")
"""

def generate_anim_tres(theme_name, tileset_texture_path):
    """Generate the animation tileset .tres file content"""
    
    return f"""[gd_resource type="Resource" script_class="UnifiedTileSprites" load_steps=3 format=3]

[ext_resource type="Script" uid="uid://qa5ggdki5k84" path="res://gameboard/resources/UnifiedTileSprites.gd" id="1_unified_sprites"]
[ext_resource type="Texture2D" path="{tileset_texture_path}" id="2_tileset_texture"]

[resource]
script = ExtResource("1_unified_sprites")
sprite_texture = ExtResource("2_tileset_texture")
tile_size = 64
sheet_columns = 6
sheet_rows = 10
static_face_count = 6
static_rows = 1
animation_frames = 5
animation_rows = 6
animation_start_row = 0
animation_fps = 6.0
"""

def generate_theme_config(palette, theme_name, output_dir):
    """Generate theme_config.json file"""
    theme_dir_name = os.path.basename(output_dir)
    
    config = {
        "name": theme_name,
        "title_path": f"res://themes/{theme_dir_name}/logo.png",
        "tileset_path": f"res://themes/{theme_dir_name}/{theme_dir_name}_tile_anim.tres",
        "bg_pattern_path": f"res://themes/{theme_dir_name}/bg_pattern.png",
        "theme_path": f"res://themes/{theme_dir_name}/{theme_dir_name}.tres",
        "background_color": palette['backgroundColor'],
        "preview_face": 0
    }
    
    return json.dumps(config, indent=2)

def main():
    if len(sys.argv) != 4:
        print("Usage: python theme_generator.py input_palette.json theme_name output_dir")
        print("Example: python theme_generator.py default_green.json \"Default Green\" themes/default_green")
        sys.exit(1)
    
    palette_file = sys.argv[1]
    theme_name = sys.argv[2]
    output_dir = sys.argv[3]
    
    # Read palette JSON
    try:
        with open(palette_file, 'r') as f:
            palette = json.load(f)
    except FileNotFoundError:
        print(f"Error: Palette file '{palette_file}' not found!")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in palette file: {e}")
        sys.exit(1)
    
    # Validate required palette fields
    required_fields = [
        'tilesetPrimary', 'tilesetOutline', 'displayPanelColor', 
        'displayPanelOutline', 'dialogPanelColor', 'dialogPanelOutline',
        'textColor', 'backgroundColor'
    ]
    
    missing_fields = [field for field in required_fields if field not in palette]
    if missing_fields:
        print(f"Error: Missing required fields in palette: {missing_fields}")
        sys.exit(1)
    
    # Create output directory
    os.makedirs(output_dir, exist_ok=True)
    
    # Generate files
    theme_dir_name = os.path.basename(output_dir)
    
    # Generate theme .tres file
    theme_content = generate_theme_tres(palette, theme_name)
    theme_file = os.path.join(output_dir, f"{theme_dir_name}.tres")
    with open(theme_file, 'w') as f:
        f.write(theme_content)
    
    # Generate animation .tres file
    tileset_texture_path = f"res://themes/{theme_dir_name}/tileset_anim.png"
    anim_content = generate_anim_tres(theme_name, tileset_texture_path)
    anim_file = os.path.join(output_dir, f"{theme_dir_name}_tile_anim.tres")
    with open(anim_file, 'w') as f:
        f.write(anim_content)
    
    # Generate theme_config.json
    config_content = generate_theme_config(palette, theme_name, output_dir)
    config_file = os.path.join(output_dir, "theme_config.json")
    with open(config_file, 'w') as f:
        f.write(config_content)
    
    print(f"Theme generated successfully!")
    print(f"Generated files in '{output_dir}':")
    print(f"  - {theme_dir_name}.tres")
    print(f"  - {theme_dir_name}_tile_anim.tres") 
    print(f"  - theme_config.json")
    print(f"\nNote: You'll still need to provide these assets manually:")
    print(f"  - logo.png")
    print(f"  - bg_pattern.png")
    print(f"  - tileset_anim.png")

if __name__ == "__main__":
    main()