# Quick Start Guide

Get up and running with Isometry in 5 minutes.

## What is Isometry?

Isometry is an isometric pixel art RPG framework. You can play campaigns created by others or build your own using JSON configuration files - no programming required.

## Prerequisites

- Isometry executable (download from releases or build from source)
- A campaign ZIP file (ask your campaign creator or use a sample campaign)

## Launching Your First Campaign

### Single Player Mode

The simplest way to launch Isometry is in single-player mode:

```bash
./isometry --campaign=my_campaign --network=none
```

Or on Windows:

```cmd
isometry.exe --campaign=my_campaign --network=none
```

**Parameters:**
- `--campaign=my_campaign` - The name of your campaign ZIP file (without .zip extension)
- `--network=none` - Launch in offline single-player mode

### Where to Put Campaign Files

Place campaign ZIP files in one of these locations:

- Same directory as the Isometry executable
- `~/.local/share/isometry/campaigns/` (Linux)
- `C:\Users\YourName\AppData\Roaming\isometry\campaigns\` (Windows)
- Custom directory specified with `--dir=/path/to/campaigns`

### Example: Launching a Sample Campaign

```bash
# Place sample_campaign.zip in the same folder as isometry
./isometry --campaign=sample_campaign --network=none
```

## Basic Controls

Once the game launches:

### Movement
- **Left Click** - Move to location
- **Hold Left Click on Actor** - Follow actor
- **Right Click** - Interact with target

### Camera
- **WASD** or **Arrow Keys** - Pan camera
- **Mouse Wheel** - Zoom in/out
- **Middle Click + Drag** - Pan camera

### Combat & Skills
- **1-9 Keys** - Use skills in action slots 1-9
- **Tab** - Cycle through nearby targets
- **Esc** - Clear target

### UI
- **T** - Open chat
- **M** - Toggle map
- **I** - Toggle inventory (if implemented by campaign)
- **Esc** - Open options menu

## Next Steps

### For Players
- See the [Playing Guide](playing.md) for complete control documentation
- Learn about [joining multiplayer games](playing.md#joining-multiplayer)

### For Campaign Creators
- Read [Campaign Basics](campaign-basics.md) to understand campaign structure
- Follow the [Minimal Campaign Tutorial](examples/minimal-campaign.md) to build your first campaign
- Explore the [Entity API](entities/README.md) to see what's possible

### For Server Operators
- Learn about [hosting multiplayer games](hosting.md)
- Understand [network security](networking.md) requirements

## Troubleshooting

### Campaign won't load

**Error: "Campaign not found"**

Check that:
- The campaign ZIP file exists
- You're using the correct filename (without .zip extension)
- The file is in a valid campaign directory

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

## Command-Line Quick Reference

```bash
# Single player
./isometry --campaign=mycampaign --network=none

# Join multiplayer game
./isometry --campaign=mycampaign --network=client --uri=server.com --port=5000 --username=player1 --password=secret

# Host a game (play + host)
./isometry --campaign=mycampaign --network=host --port=5000 --username=admin --password=adminpass

# Run dedicated server (headless)
./isometry --campaign=mycampaign --network=server --port=5000 --username=server --password=serverpass
```

See the complete [CLI Reference](cli-reference.md) for all options.

## Getting Help

- **Read the docs** - [Full documentation](README.md)
- **Common issues** - [Troubleshooting guide](troubleshooting.md)
- **Report bugs** - Include `--log-level=trace` output

---

**Next:** [Playing Guide](playing.md) | [Campaign Creation](campaign-basics.md) | [Back to Home](README.md)
