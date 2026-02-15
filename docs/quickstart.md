# Quick Start Guide

Get up and running with Isometry in 5 minutes.

## What is Isometry?

Isometry is an isometric pixel art RPG framework. You can play campaigns created by others or build your own using JSON configuration files - no programming required.

## Getting Started

Download the latest release ZIP for your platform. It contains:

- **Isometry Launcher** - a graphical launcher for configuring and starting games
- **Isometry** - the game engine itself
- **campaigns/** - a folder containing campaign `.zip` files (includes a demo campaign)

Extract the ZIP and place it wherever you like. No installation required.

## Launching Your First Campaign

1. Run the **Isometry Launcher** (`isometry_launcher_linux.x86_64`, `isometry_launcher_windows.exe`, or `isometry_launcher_macos.app` depending on your platform)
2. The launcher will automatically detect campaigns in the `campaigns/` folder next to it
3. Select a campaign from the dropdown
4. Fill in a **Username** and **Password**
5. Click **Host** to start a game, or **Join** to connect to an existing game

The launcher will start the Isometry game engine with your chosen settings. To play solo, just **Host** a game without sharing the connection details.

### Where to Put Campaign Files

Place campaign `.zip` files in the `campaigns/` folder next to the launcher executable. The launcher scans this directory on startup.

## Basic Controls

### Movement

- **Right Click** - Move to a destination (pathfinding)
- **Arrow Keys** - Move directly in a direction (hold to keep moving)
- **W / A / S / D** - Change facing direction (bearing)

### Camera

- **Space** - Toggle camera lock on your character (hold to temporarily recenter)
- **Page Up / Mouse Wheel Up** - Zoom in
- **Page Down / Mouse Wheel Down** - Zoom out

The camera follows your character by default and also pans automatically when your cursor is near the screen edges.

### Targeting

- **Tab** - Cycle to next target
- **Shift + Tab** - Cycle to previous target
- **F** - Target self
- **Esc** - Clear target
- **=** / **-** - Cycle through target groups

### Skills

- **Q / W / E / R / T / Y / U / I / O** - Activate skills in action slots 1-9 (hold to charge, release to fire if the skill supports charging)

### UI

- **Enter** - Open chat
- **C** - Cycle chat channel
- **` (Backtick)** - Open context menu for current target
- **Home** - Open global menu
- **Esc** - Clear target / close current menu
- **F1-F4** - Set focus targets (Shift+F1-F4 to clear)

### Resources

Campaigns define **resources** for your character (such as health, mana, currency, etc.). These are visible in the resources panel when your character has them. There is no generic inventory - resources are defined entirely by the campaign you're playing.

## Next Steps

### For Players
- See the [Playing Guide](playing.md) for complete control documentation
- Learn about [joining multiplayer games](playing.md#joining-multiplayer)

### For Campaign Creators
- Read [Campaign Basics](campaign-basics.md) to understand campaign structure
- Explore the [Entity API](entities/README.md) to see what's possible

### For Server Operators
- Learn about [hosting multiplayer games](hosting.md)
- Understand [network security](networking.md) requirements

## Troubleshooting

### Campaign won't load

**Launcher shows "(no campaigns found)"**

Check that campaign `.zip` files are in the `campaigns/` folder next to the launcher executable.

**Error: "Validation failed"**

The campaign has errors in its JSON files. Ask the campaign creator for a fixed version, or see [Troubleshooting](troubleshooting.md#validation-errors) for details.

### Controls aren't working

- Make sure the game window has focus
- Check that your campaign has assigned skills to action slots
- Try pressing **Esc** to ensure no modal dialogs are blocking input

### Performance issues

- Try lowering your resolution
- Reduce zoom level (zoom out)
- Check your campaign's actor count (too many NPCs can impact performance)

## Getting Help

- **Read the docs** - [Full documentation](README.md)
- **Common issues** - [Troubleshooting guide](troubleshooting.md)
- **Report bugs** - Include `--log-level=trace` output

---

**Next:** [Playing Guide](playing.md) | [Campaign Creation](campaign-basics.md) | [Back to Home](README.md)
