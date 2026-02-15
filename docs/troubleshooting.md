# Troubleshooting Guide

Common issues and solutions for Isometry.

## Campaign Loading Issues

### Campaign Not Found

**Error:** `Campaign 'my_campaign' not found`

**Causes:**
- ZIP file doesn't exist
- Wrong filename
- Wrong directory

**Solutions:**
```bash
# Check file exists
ls my_campaign.zip

# Verify filename matches (without .zip)
isometry --campaign=my_campaign --network=none

# Specify custom directory
isometry --campaign=my_campaign --dir=/path/to/campaigns
```

### Validation Errors

**Error:** `Campaign validation failed with N error(s)`

**Common validation errors:**

#### Missing Required Field
```
ERROR: Actor 'hero' missing required field 'sprite'
```
**Fix:** Add the missing field to your JSON

#### Invalid KeyRef
```
ERROR: Actor 'hero' references sprite 'missing_sprite' which doesn't exist
```
**Fix:** Create the referenced entity or fix the key name

#### Asset Not Found
```
ERROR: Sprite 'hero_sprite' texture 'wrong/path.png' not in archive
```
**Fix:** Add the asset file to ZIP or correct the path

#### Invalid Type
```
ERROR: Actor 'hero' field 'base' must be Int, got String
```
**Fix:** Remove quotes from numbers: `"base": 32` not `"base": "32"`

#### Float Field Given Integer
```
ERROR: Parallax 'farBg' field 'effect' must be Float, got Int
```
**Fix:** Always include a decimal point for Float fields: `"effect": 20.0` not `"effect": 20`. The validator accepts `3.0` for Int fields but does **not** accept `3` for Float fields.

#### Main Entity Issues
```
ERROR: Campaign requires exactly one Main entity (found 0)
```
**Fix:** Add a Main entity to your campaign

#### Duplicate Keys
```
ERROR: Duplicate entity key 'warrior' found in Actor and Sprite
```
**Fix:** Rename one entity to make keys unique

### Campaign Checksum Mismatch

**Error:** `Campaign mismatch between client and server`

**Solution:**
1. Delete client's campaign ZIP
2. Download exact copy from server operator
3. Verify SHA-256 hash matches
4. Reconnect

## Network Issues

### Cannot Connect to Server

**Error:** `Connection failed` or timeout

**Solutions:**

1. **Verify server is running:**
```bash
# On server
sudo netstat -ulnp | grep 5000
```

2. **Check firewall:**
```bash
# Allow UDP port
sudo ufw allow 5000/udp
```

3. **Test connectivity:**
```bash
# From client machine
nc -u SERVER_IP 5000
```

4. **Verify port forwarding** (if hosting from home)

### Authentication Failed

**Error:** `Authentication failed`

**Causes:**
- Invalid username/password
- Invalid characters in credentials
- Server-side user management issue

**Solutions:**
1. Check credentials don't contain: `<>:"/\|?*~!@#$%^&()={}[];.` or backticks
2. Verify username/password with server operator
3. Try simpler credentials (alphanumeric only)

### Port Already in Use

**Error:** `Port 5000 already in use`

**Solutions:**
```bash
# Find process using port
sudo lsof -i :5000

# Use different port
isometry --campaign=test --network=server --port=7777

# Kill conflicting process (if safe)
sudo kill <PID>
```

## Performance Issues

### Low FPS / Lag

**Causes:**
- Too many NPCs
- Complex actions
- Large maps
- Inefficient behaviors

**Solutions:**

1. **Reduce NPC count:**
   - Fewer deployments
   - Despawn inactive NPCs

2. **Simplify actions:**
   - Avoid excessive AoE
   - Reduce trigger frequency
   - Simplify AI strategies

3. **Optimize maps:**
   - Smaller tilemaps
   - Fewer parallax layers
   - Compress assets

4. **Client-side:**
   - Lower resolution
   - Zoom out
   - Close other programs

### High Memory Usage

**Causes:**
- Memory leaks
- Too many spawned actors
- Large textures

**Solutions:**
1. Monitor with `htop` or Task Manager
2. Reduce actor count
3. Check for circular action references
4. Restart server periodically

## Gray Screen / Nothing Renders

### Stale Save File

**Symptom:** Campaign loads but shows a gray screen, or the wrong map/actor appears.

**Cause:** A save file from a previous session contains outdated `actor` and `map` values that override the Main entity's defaults. When the player spawns, the engine merges saved data into the spawn parameters. If the saved keys reference entities that no longer exist, loading fails silently.

**Fix:** Delete the save file in the game's data directory (typically `data/` next to the game binary). Save files are named by a numeric hash (e.g., `155582795.json`).

### Ghost Tiles Making Terrain Invisible

**Symptom:** Map loads, parallax shows, actor spawns, but no terrain tiles are visible.

**Cause:** Tiles with `ghost: true` are not rendered — they only exist for pathfinding. If your primary floor tile has `ghost: true`, the entire terrain will be invisible.

**Fix:** Remove `ghost: true` from walkable floor tiles. Only use ghost on tiles that should be invisible navigation helpers.

### Parallax Shows Then Disappears

**Symptom:** Background flashes briefly then everything goes gray.

**Cause:** Usually indicates the actor or map failed to load. The parallax renders during initial load, but the transition screen (fade from black) covers it. If the actor doesn't spawn, the camera never positions correctly and the map never enables.

**Fix:** Check logs for actor/map loading errors. Verify the Main entity's `actor` and `map` keys reference valid entities. Delete any stale save files (see above).

## Gameplay Issues

### Controls Not Responding

**Causes:**
- Window doesn't have focus
- Modal dialog blocking input
- No skills assigned

**Solutions:**
1. Click game window
2. Press Esc to close dialogs
3. Verify campaign has skills assigned to actor

### Can't See Character

**Causes:**
- Camera not centered
- Wrong map
- Actor not spawned
- Spawn coordinates outside the tile grid

**Solutions:**
1. Press Esc to recenter camera
2. Check you're on correct map
3. Look for spawn errors in logs
4. Verify spawn coordinates (Vertex) are within the isometric world bounds of your tile grid. Use the coordinate formula: `world_x = (tile_x - tile_y) * 16`, `world_y = (tile_x + tile_y) * 8` to calculate valid positions

### Tiles Not Visible Despite Correct Map

**Causes:**
- Fog of war: tiles start fully transparent until discovered
- Actor's `perception` too low to reveal tiles
- Spawn point too far from tile grid

**Solutions:**
1. Tiles become visible when the actor's discovery area overlaps them — this is the fog of war system, not a bug
2. Increase the actor's `perception` value (controls discovery radius)
3. Ensure the spawn Vertex is positioned over walkable tiles

### Skills Won't Activate

**Causes:**
- No target (if required)
- Insufficient resources
- Condition not met

**Solutions:**
1. Target valid actor (Tab or click)
2. Check resource requirements (mana, stamina)
3. Verify skill conditions

## Development Issues

### JSON Syntax Errors

**Error:** `Failed to parse JSON`

**Common mistakes:**

```json
// BAD - Trailing comma
{
  "Actor": {
    "hero": { "name": "Hero" },  // <-- Remove this comma
  }
}

// BAD - Missing quotes
{
  "Actor": {
    hero: { "name": "Hero" }  // <-- Should be "hero"
  }
}

// BAD - Single quotes
{
  'Actor': {  // <-- Use double quotes
    'hero': { 'name': 'Hero' }
  }
}

// GOOD
{
  "Actor": {
    "hero": { "name": "Hero" }
  }
}
```

### Action Function Not Found

**Error:** `Action 'my_action' references unknown function 'invalid_func'`

**Solution:**
- Use valid action function from [Action Reference](actions/reference.md)
- Check spelling matches exactly

### Circular References

**Problem:** Actions reference each other infinitely

**Example:**
```json
{
  "Action": {
    "action_a": {"do": "echo", "then": "action_b"},
    "action_b": {"do": "echo", "then": "action_a"}  // Infinite loop!
  }
}
```

**Solution:** Add condition to break loop or remove circular reference

## Debugging

### Enable Trace Logging

```bash
isometry --campaign=test --network=none --log-level=trace
```

Shows detailed execution flow for debugging.

### Check Log Files

**Linux:** `~/.local/share/isometry/logs/`  
**Windows:** `C:\Users\Name\AppData\Roaming\isometry\logs\`

### Validate Campaign

Run campaign in single-player mode first:
```bash
isometry --campaign=test --network=none --log-level=debug
```

Validation runs automatically on load.

## Getting Help

1. **Check documentation** - [docs/README.md](README.md)
2. **Search issues** - GitHub issues tracker
3. **Ask community** - Discord/forums
4. **Report bugs** - Include `--log-level=trace` output

### Bug Report Template

```
**Description:**
Brief description of the issue

**Steps to Reproduce:**
1. Launch with: isometry --campaign=...
2. Click...
3. Error occurs

**Expected Behavior:**
What should happen

**Actual Behavior:**
What actually happens

**Log Output:**
(Paste output with --log-level=trace)

**Environment:**
- OS: Linux/Windows/Mac
- Isometry version: X.Y.Z
- Campaign: name.zip
```

---

**Back to [Documentation Home](README.md)**
