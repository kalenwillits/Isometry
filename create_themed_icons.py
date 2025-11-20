#!/usr/bin/env python3
"""
Create theme-specific SVG icon variants with proper fill colors.
"""

import os
import re

# Icon files to process
ICONS = [
    'compass-solid-full',
    'eye-solid-full',
    'crosshairs-solid-full'
]

# Theme colors from theme_manager.gd icon_color property
THEME_COLORS = {
    'dark': 'e0e0e0',
    'light': '2a2a2a',
    'monokai': 'f8f8f2',
    'dracula': 'f8f8f2',
    'solarized-dark': '93a1a1',
    'nord': 'd8dee9',
    'gruvbox': 'd5c4a1',
    'one-dark': 'abb2bf',
    'tokyo-night': 'a9b1d6',
    'cobalt': 'c0c0c0',
    'material': 'eceff1',
    'atom-one-light': '383a42'
}

ICON_DIR = 'app/assets/generic-icons'

def process_svg(svg_content, fill_color):
    """Add fill attribute to SVG path element."""
    # Check if fill already exists
    if 'fill=' in svg_content:
        # Replace existing fill
        svg_content = re.sub(r'fill="[^"]*"', f'fill="#{fill_color}"', svg_content)
    else:
        # Add fill attribute to <path> tag
        # Match <path and any attributes up to d="..." and add fill after d
        svg_content = re.sub(
            r'(<path\s+d="[^"]*")',
            rf'\1 fill="#{fill_color}"',
            svg_content
        )

    return svg_content

def main():
    created_files = []

    for icon_name in ICONS:
        source_file = os.path.join(ICON_DIR, f'{icon_name}.svg')

        # Read source SVG
        if not os.path.exists(source_file):
            print(f"Warning: {source_file} not found, skipping...")
            continue

        with open(source_file, 'r') as f:
            svg_content = f.read()

        # Create variant for each theme
        for theme_name, color in THEME_COLORS.items():
            themed_svg = process_svg(svg_content, color)
            output_file = os.path.join(ICON_DIR, f'{icon_name}-{theme_name}.svg')

            with open(output_file, 'w') as f:
                f.write(themed_svg)

            created_files.append(output_file)
            print(f"Created: {output_file}")

    print(f"\nTotal files created: {len(created_files)}")
    print(f"Icons: {len(ICONS)}")
    print(f"Themes: {len(THEME_COLORS)}")

if __name__ == '__main__':
    main()
