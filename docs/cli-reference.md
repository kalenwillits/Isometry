# Command-Line Reference

Complete reference for all Isometry command-line arguments.

## Synopsis

```bash
isometry --campaign=NAME [OPTIONS]
```

## Required Arguments

### `--campaign=NAME`

Campaign archive to load (without .zip extension).

**Examples:**
```bash
--campaign=my_campaign
--campaign=dungeon_crawler
```

## Network Mode

### `--network=MODE`

Network mode for multiplayer support.

**Values:**
- `none` or `0` - Single-player offline
- `host` or `1` - Host + play
- `server` or `2` - Dedicated server (headless)
- `client` or `3` - Connect to server

**Default:** `0` (none)

**Examples:**
```bash
--network=none     # Single-player
--network=host     # Host for friends
--network=server   # Dedicated server
--network=client   # Join server
```

## Connection Options

### `--uri=ADDRESS`

Server hostname or IP address (client mode only).

**Default:** `localhost`

**Examples:**
```bash
--uri=localhost
--uri=192.168.1.100
--uri=myserver.example.com
```

### `--port=NUMBER`

Server port (all network modes).

**Default:** `5000`

**Range:** 1-65535

**Examples:**
```bash
--port=5000
--port=7777
```

## Authentication

### `--username=NAME`

Username for authentication (host/server/client modes).

**Requirements:**
- Alphanumeric + underscore/dash only
- No special characters: `<>:"/\|?*~!@#$%^&()={}[];.` or backticks

**Examples:**
```bash
--username=player1
--username=admin
```

### `--password=PASS`

Password for authentication (host/server/client modes).

**Requirements:** Same as username

**Examples:**
```bash
--password=secret123
```

## Other Options

### `--dir=PATH`

Custom campaign directory path.

**Default:** 
- Same directory as executable
- `~/.local/share/isometry/campaigns/` (Linux)
- `C:\Users\Name\AppData\Roaming\isometry\campaigns\` (Windows)

**Examples:**
```bash
--dir=/opt/isometry/campaigns
--dir=C:\Games\Isometry\Campaigns
```

### `--log-level=LEVEL`

Logging verbosity.

**Values:**
- `trace` - Maximum verbosity (debugging)
- `debug` - Detailed information
- `info` - General information (default)
- `warn` - Warnings only
- `error` - Errors only

**Examples:**
```bash
--log-level=info
--log-level=trace
```

## Complete Examples

### Single-Player

```bash
isometry --campaign=my_adventure --network=none
```

### Host Game

```bash
isometry --campaign=dungeon_quest \
  --network=host \
  --port=5000 \
  --username=host_player \
  --password=secret
```

### Dedicated Server

```bash
isometry --campaign=pvp_arena \
  --network=server \
  --port=7777 \
  --username=server \
  --password=admin123 \
  --log-level=info
```

### Join Server

```bash
isometry --campaign=pvp_arena \
  --network=client \
  --uri=myserver.com \
  --port=7777 \
  --username=player1 \
  --password=player_pass
```

## Network Mode Comparison

| Mode | Play | Host | Headless | Use Case |
|------|------|------|----------|----------|
| **none** (0) | ✅ | ❌ | ❌ | Single-player |
| **host** (1) | ✅ | ✅ | ❌ | Play with friends |
| **server** (2) | ❌ | ✅ | ✅ | Dedicated server |
| **client** (3) | ✅ | ❌ | ❌ | Join multiplayer |

## Troubleshooting

### Campaign not found

```bash
ERROR: Campaign 'my_campaign' not found
```

**Solutions:**
- Verify ZIP file exists
- Check filename (without .zip)
- Use `--dir` to specify custom path

### Authentication failed

```bash
ERROR: Authentication failed
```

**Solutions:**
- Check username/password don't contain invalid characters
- Verify credentials with server operator
- Ensure campaign checksum matches server

### Port already in use

```bash
ERROR: Port 5000 already in use
```

**Solutions:**
- Choose different port with `--port`
- Stop other process using the port
- Use `sudo lsof -i :5000` (Linux) to find process

---

**Back to [Documentation Home](README.md)**
