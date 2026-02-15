# Isometry Framework Documentation

**Isometry** is an isometric pixel art RPG framework built with Godot. It provides a complete, data-driven system for creating custom campaigns with multiplayer support, AI behaviors, and rich gameplay mechanics.

## Quick Links

- **[Quick Start Guide](quickstart.md)** - Get up and running in 5 minutes
- **[CLI Reference](cli-reference.md)** - Command-line arguments
- **[Entity API](entities/README.md)** - All 30 entity types
- **[Philosophy](philosophy.md)** - Why Isometry was built this way

## Table of Contents

### Getting Started
- [Quick Start Guide](quickstart.md) - Launch your first campaign in 5 minutes
- [Playing Campaigns](playing.md) - Player controls and gameplay mechanics
- [Command-Line Reference](cli-reference.md) - All CLI arguments and launch options

### Multiplayer & Networking
- [Hosting Games](hosting.md) - Host mode vs Server mode
- [Network Security](networking.md) - Authentication, encryption, and advanced deployments

### Creating Campaigns
- [Campaign Basics](campaign-basics.md) - Campaign structure, validation, and the Main entity
- [Entity System Overview](entities/README.md) - Understanding the entity-based architecture

#### Entity Documentation
- [Core Entities](entities/core-entities.md) - Main, Map, Actor
- [Action System](entities/action-system.md) - Action, Condition, Parameter
- [Resources & Measures](entities/resources.md) - Resource, Measure
- [Skills](entities/skills.md) - Skill entity and action slots
- [AI System](entities/ai-system.md) - Strategy, Behavior, Trigger, Timer

### Reference
- [CLI Reference](cli-reference.md) - Complete command-line documentation
- [Design Philosophy](philosophy.md) - Why isometric? Why pixel art? Design principles
- [Troubleshooting](troubleshooting.md) - Common issues and solutions

## What is Isometry?

Isometry is a **highly opinionated** framework for creating isometric pixel art RPGs. It combines:

- **Data-Driven Design** - Define everything in JSON, no coding required
- **Multiplayer Support** - Client-server architecture with RSA authentication
- **Rich Action System** - 62 built-in actions for combat, movement, and interaction
- **AI Behaviors** - Goal-based AI system for NPCs
- **Campaign Modularity** - ZIP-based campaigns that work like D&D homebrew modules

### Key Features

✅ **30 Entity Types** - Actors, Maps, Actions, Skills, Resources, and more
✅ **62 Actions** - Movement, combat, targeting, spawning, and UI actions
✅ **Multiplayer Ready** - Host, server, and client modes with secure authentication
✅ **AI System** - Strategies, behaviors, triggers, and timers for NPC automation
✅ **Isometric Rendering** - Classic CRPG aesthetic with Y-sorting and elliptical collision
✅ **Dice Expressions** - D&D-style dice notation (2d6+3) for dynamic values
✅ **Validation System** - Built-in campaign validation with helpful error messages

## Who is Isometry For?

### Campaign Creators
Create custom RPG campaigns without programming. Define characters, maps, skills, and behaviors entirely in JSON files. Perfect for game designers, storytellers, and D&D dungeon masters who want to bring their worlds to life.

### Indie Developers
Use Isometry as a foundation for your isometric RPG. The framework handles multiplayer networking, action systems, AI, and rendering so you can focus on content and gameplay design.

### Pixel Artists
Isometry embraces pixel art as an accessibility feature. The isometric perspective provides visual depth while maintaining the charm and efficiency of pixel graphics.

## Design Philosophy

Isometry is built on several core principles:

**Isometric Perspective** - Provides visual clarity and depth while maintaining a rigid grid system that makes asset reuse easy.

**Pixel Art First** - Easy to start, hard to master. Pixel art is accessible for indie creators while maintaining timeless aesthetic appeal.

**Data-Driven Everything** - Campaigns are 100% JSON. No code changes required to create new content. Like D&D homebrew, but for video games.

**Opinionated Constraints** - 9 action slots maximum. Resource-based everything. No hard-coded game logic. These constraints make campaigns easier to create and balance.

Read more in the [Design Philosophy](philosophy.md) document.

## Network Security Notice

**Isometry provides authentication and encryption, but individual campaign creators and server operators are responsible for network security.**

- Server operators must secure their infrastructure
- Username/password credentials are encrypted with RSA
- Campaign checksums prevent version mismatches
- Network security is the responsibility of server operators

See [Network Security](networking.md) for detailed information.

## Getting Help

- **Documentation Issues** - Open an issue on GitHub
- **Campaign Creation Questions** - Check [Troubleshooting](troubleshooting.md) first
- **Bug Reports** - Include log output with `--log-level=trace`

## License

See the main repository for license information.

---

**Ready to get started?** Jump to the [Quick Start Guide](quickstart.md) to launch your first campaign in 5 minutes.
