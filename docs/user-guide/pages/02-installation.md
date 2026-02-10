# Installation & Setup

## Downloading Isometry

Download the appropriate build for your platform:

- **Linux**: `isometry_linux.x86_64`
- **Windows**: `isometry_windows.exe`
- **macOS**: `isometry_macos.zip`

## Installing Campaigns

Campaign files are ZIP archives containing JSON entity definitions and assets. Place them in one of these locations:

- Same directory as the Isometry executable
- A `campaigns/` subdirectory next to the executable
- A custom path specified with `--dir=/path/to/campaigns`

## Using the Launcher

The Isometry Launcher provides a graphical interface for starting games:

1. Run `isometry_launcher_linux.x86_64` (or the Windows equivalent)
2. Enter your **username** and **password**
3. Select a **campaign** from the dropdown
4. Enter the **URI** and **port** (defaults: localhost:5000)
5. Click **HOST** to start a server, or **JOIN** to connect to one

## Command-Line Launch

For advanced users, Isometry supports direct CLI launch:

```bash
# Single player (host mode, localhost)
./isometry_linux.x86_64 --campaign=demo --network=host --port=5000 \
  --username=player1 --password=secret

# Join a multiplayer server
./isometry_linux.x86_64 --campaign=demo --network=client \
  --uri=server.example.com --port=5000 \
  --username=player1 --password=secret

# Run a dedicated server
./isometry_linux.x86_64 --campaign=demo --network=server --port=5000 \
  --username=server --password=serverpass
```

### CLI Arguments Reference

| Argument | Description | Default |
|----------|-------------|---------|
| `--campaign=NAME` | Campaign name (without .zip) | Required |
| `--network=MODE` | `host`, `server`, `client`, or `none` | Required |
| `--uri=HOST` | Server address | `localhost` |
| `--port=PORT` | Server port (1024-65535) | `5000` |
| `--dir=PATH` | Campaign directory path | auto-detected |
| `--username=NAME` | Player display name | Required |
| `--password=PASS` | Authentication password | Required |
| `--log-level=LEVEL` | `trace`, `debug`, `info`, `warn`, `error` | `info` |
| `--delay=MS` | Connection delay in milliseconds | `0` |

## Building from Source

If you have the source code and Godot 4.4+:

```bash
# Build for Linux
./build_linux.sh

# Build for Windows (cross-compile)
./build_windows.sh

# Build the launcher
./build_launcher.sh linux
./build_launcher.sh windows
```
