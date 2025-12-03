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

**Solutions:**
1. Press Esc to recenter camera
2. Check you're on correct map
3. Look for spawn errors in logs

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
