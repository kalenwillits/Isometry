# Isometry

An isometric pixel art RPG framework built with Godot 4.4. Create multiplayer campaigns using JSON configuration files.

## Quick Start

### Playing

1. Download the build for your platform from releases
2. Place campaign `.zip` files in a `campaigns/` directory next to the executable
3. Run the launcher or use the CLI:

```bash
./isometry_linux.x86_64 --campaign=demo --network=host \
  --port=5000 --username=player1 --password=secret
```

### Building from Source

Requires [Godot 4.4+](https://godotengine.org/) with export templates installed.

```bash
# Build game
./build_linux.sh
./build_windows.sh

# Build launcher
./build_launcher.sh linux
./build_launcher.sh windows

# Package demo campaign
./build_demo_campaign.sh
```

## Project Structure

```
atlas/
├── app/                  # Godot project
│   ├── autoload/         # Global singletons
│   ├── classes/          # Utility classes
│   ├── entities/         # 30 entity type definitions
│   ├── scenes/           # Scene files and scripts
│   ├── validation/       # Campaign data validators
│   └── project.godot     # Engine configuration
├── campaigns/            # Campaign source data
│   └── demo/             # Demo campaign (all entity types)
├── docs/                 # Documentation
│   ├── user-guide/       # Player guide (ebk format)
│   └── sdk-reference/    # Content creator SDK (ebk format)
├── build_linux.sh        # Linux build script
├── build_windows.sh      # Windows build script
├── build_macos.sh        # macOS build placeholder
├── build_launcher.sh     # Launcher build script
└── build_demo_campaign.sh
```

## Documentation

- **[User Guide](docs/user-guide/)** - Installation, controls, hosting
- **[SDK Reference](docs/sdk-reference/)** - Campaign creation, all 30 entity types
- **[Quick Start](docs/quickstart.md)** - Get running in 5 minutes

Build docs as EPUB using [ebk](https://github.com/anthropics/ebk):

```bash
cd docs/user-guide && ebk
cd docs/sdk-reference && ebk
```

## License

CC BY-NC 4.0 with additional terms. See [LICENSE.md](LICENSE.md).

Free for non-commercial use. Content creators may sell user-generated campaigns. All commercial rights reserved by Dark Mode Games.
