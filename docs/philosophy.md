# Design Philosophy

Why Isometry was built the way it was.

## Why does this need to exist?

There's no good way to make a multiplayer isometric RPG without building one from scratch. General-purpose engines like Unity and Godot give you all the tools, but you still have to write thousands of lines of code for networking, entity systems, action resolution, and all the glue that holds an RPG together. RPG Maker is accessible but locked to top-down single-player games. Tabletop simulators automate nothing — you're still rolling dice by hand.

Isometry fills the gap: a framework that handles the hard parts (rendering, networking, entity management, action resolution) so that campaign creators can focus on designing content rather than writing code.

## Why pixel art?

Pixel art is the most accessible visual style for indie creators. Anyone can open a sprite editor and produce something usable in an afternoon. It doesn't require 3D modeling skills, rigging, or complex shader knowledge. Pixel art also ages well — a well-made sprite from 2005 looks just as good today. Small file sizes keep campaigns lightweight and easy to distribute.

## Why isometric?

Isometric projection gives you a sense of depth and space without the complexity of a full 3D engine. It's the natural perspective for tactical RPGs where you need to see the battlefield, position characters, and understand spatial relationships. The fixed camera angle also simplifies asset creation — sprites only need a limited set of directional frames rather than full 3D models. It's the perspective used by classics like Baldur's Gate, Diablo, and Fallout for good reason.

## Why JSON for content?

Campaign creators shouldn't need to be programmers. JSON is human-readable, easy to validate, and can be edited in any text editor. It enforces a clear structure that makes campaigns predictable and debuggable. Every actor, map, skill, item, and quest is defined declaratively — you describe *what* things are rather than writing code for *how* they work. This is analogous to writing a D&D module: you define the world and its rules, and the engine handles execution.

## Why a single executable?

Distribution should be simple. A single binary with no installer, no runtime dependencies, and no setup wizard means anyone can download it, drop it in a folder, and run it. Campaign files are just ZIP archives placed next to the executable. This makes it trivial to host a server, share builds with players, or bundle a campaign for distribution.

## Why CLI arguments?

Isometry is launched via command-line arguments (`--campaign`, `--network`, `--port`, etc.) rather than an in-app menu system. This is a deliberate choice to support content creators writing their own launchers. A creator distributing their campaign can build a custom launcher UI (in any language or framework they prefer) that invokes the Isometry executable with the right arguments. It also makes server deployment straightforward — you can run it in a shell script, a systemd service, or a Docker container without any interactive setup.

## Why multiplayer from the start?

Networking was built into the architecture from day one rather than bolted on later. Retrofitting multiplayer onto a single-player engine is notoriously difficult and leads to hacks and limitations. By designing around a client-server model from the beginning, every system (actions, entity state, spawning) works correctly in both single-player and multiplayer without special cases. Single-player mode is just a server with one connected client.

## Why opinionated constraints?

Isometry limits certain things on purpose. Skills are capped at 9 action slots because that maps to the 1-9 keys and forces creators to design focused ability sets rather than bloated hotbars. All stats (health, mana, gold, experience) use the same Resource system because a unified model is easier to learn, easier to validate, and easier to trigger events from. There's no hard-coded game logic because every special case is a barrier to modding. These constraints exist to make campaign creation simpler, not to limit creativity.

---

**Back to [Documentation Home](README.md)**
