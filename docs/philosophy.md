# Design Philosophy

Why Isometry was built the way it was.

## Core Principles

Isometry is built on several fundamental design decisions that shape every aspect of the framework.

### 1. Isometric Perspective

**Why isometric?**

- **Visual clarity** - Isometric projection provides clear depth perception without 3D complexity
- **Classic CRPG tradition** - Follows in the footsteps of Baldur's Gate, Diablo, Fallout
- **Asset reuse** - Rigid grid system makes it easy to reuse tiles and sprites
- **2:1 ellipse collision** - Natural feel for character movement and selection

**Trade-offs:**
- Limited camera angles (fixed perspective)
- Requires specific sprite orientations (8-directional)
- Not suitable for platformers or first-person games

### 2. Pixel Art First

**Why pixel art?**

- **Accessibility** - Easy to start creating art, even for non-artists
- **Timeless aesthetic** - Pixel art ages gracefully, never looks "dated"
- **Performance** - Small file sizes, efficient rendering
- **Clear communication** - Simple visuals convey information effectively

**Philosophy:** "Easy to start, hard to master"

Pixel art lowers the barrier to entry for indie creators while still allowing room for artistic mastery.

### 3. Data-Driven Everything

**Why JSON over code?**

- **No programming required** - Campaign creators don't need to be programmers
- **Moddability first** - Everything is editable without touching engine code
- **D&D homebrew analogy** - Like creating custom D&D modules
- **Rapid iteration** - Change numbers, test immediately

**What this means:**
- Zero hard-coded game logic
- Campaign is the single source of truth
- Engine reads data, doesn't define gameplay

### 4. Opinionated Constraints

Isometry deliberately limits certain things to make campaign creation easier.

#### 9 Action Slots Maximum

**Why limit to 9 skills?**

- **Discoverability** - Players can see all abilities at a glance
- **Keyboard ergonomics** - 1-9 keys are easily accessible
- **Forces meaningful choices** - Creators must design focused kits
- **Prevents bloat** - Avoids 40-skill MMO hotbar syndrome

#### Resource-Based Everything

**Why resources for all stats?**

- **Unified system** - Health, mana, gold, experience all work the same way
- **Trigger integration** - Easy to respond to any stat change
- **Simplicity** - One mechanism to learn and understand

#### No Hard-Coded Game Logic

**Why avoid special cases?**

- **Predictability** - Everything works through the same action system
- **Moddability** - No "this enemy is special and can't be changed"
- **Debugging** - Easier to trace problems when logic is data

### 5. Multiplayer by Default

**Why build networking from the start?**

- **Shared experiences** - Games are better with friends
- **Campaign longevity** - Multiplayer extends replay value
- **Design forcing function** - Multiplayer-first prevents local-only shortcuts

**Architecture:**
- Client-server (authoritative server)
- Peer ID system for players and NPCs
- RSA authentication
- Campaign checksum validation

## Design Decisions

### Entity-Based Architecture

**Everything is an entity:**
- Actors, Maps, Skills, Actions
- Sprites, Sounds, Menus
- Even coordinates (Vertex) and shapes (Polygon)

**Benefits:**
- Consistent data model
- Easy to validate
- KeyRef system for relationships
- Repository pattern for querying

### Action System

**Actions are the verbs of Isometry:**
- 69 built-in action functions
- Parameters for customization
- Conditional execution (if/else/then)
- Chaining for sequences

**Design goal:** Enable complex behaviors through data alone.

### KeyRef System

**Why references instead of inline data?**

- **Reusability** - Define once, reference many times
- **Validation** - Ensure all references are valid
- **Organization** - Separate concerns cleanly

```json
{
  "Actor": {
    "warrior": {"sprite": "warrior_sprite"}  // Reference
  },
  "Sprite": {
    "warrior_sprite": {...}  // Definition
  }
}
```

Better than:
```json
{
  "Actor": {
    "warrior": {
      "sprite": {"texture": "...", "size": {...}}  // Inline
    }
  }
}
```

### Dice Expressions

**Why dice notation?**

- **Familiar to tabletop gamers** - "2d6+3" is immediately understood
- **Built-in randomness** - No need for separate random number fields
- **Expressiveness** - Can represent fixed values ("10") or ranges ("1d20")

Used for:
- Damage/healing amounts
- Timer intervals
- Measure calculations

## What Isometry Is NOT

### Not a General-Purpose Engine

Isometry is opinionated and specialized:
- ❌ Not for platformers
- ❌ Not for FPS games
- ❌ Not for racing games
- ✅ Perfect for tactical RPGs
- ✅ Perfect for dungeon crawlers
- ✅ Perfect for MOBA-style games

### Not Click-and-Drag

Isometry requires JSON editing:
- ❌ No visual campaign editor (yet)
- ❌ No drag-and-drop UI builder
- ✅ Text editor + JSON knowledge required

**Trade-off:** Less accessible, but more powerful and precise.

### Not Asset-Complete

Isometry is a framework, not a game:
- ❌ No included sprites or tilesets
- ❌ No included sound effects or music
- ✅ You provide all assets
- ✅ Full creative control

## Comparisons

### vs Unity/Godot

**Isometry:**
- Specialized for isometric RPGs
- No programming required
- Data-driven campaigns
- Multiplayer built-in

**Unity/Godot:**
- General-purpose engines
- Full programming required
- Build anything
- Networking is add-on

### vs RPG Maker

**Isometry:**
- Isometric (not top-down)
- JSON-based (not GUI)
- Multiplayer support
- Modern architecture

**RPG Maker:**
- Top-down 2D
- Visual editor
- Single-player focused
- Event-based scripting

### vs Tabletop Simulators

**Isometry:**
- Automated rules
- Real-time action
- Video game feel
- Pixel art aesthetic

**Tabletop:**
- Manual rules
- Turn-based
- Physical simulation
- Board game feel

## Best Practices

### Campaign Design

1. **Start simple** - Create minimal campaign first
2. **Test early** - Validate frequently
3. **Iterate** - Add complexity gradually
4. **Organize** - Use clear directory structure
5. **Document** - Add notes to Main entity

### Resource Design

1. **Name clearly** - "health" not "hp"
2. **Set realistic bounds** - min/max appropriate for gameplay
3. **Use public/private wisely** - Not everything needs to be visible

### Action Design

1. **Atomic actions** - Each action does one thing well
2. **Chain for complexity** - Use then/else for sequences
3. **Test in isolation** - Verify each action works alone

### Skill Design

1. **Clear purpose** - Each skill should have obvious use case
2. **Visual feedback** - Use animations and sounds
3. **Balance cooldowns** - Don't overwhelm players with spam

## Future Directions

### Potential Additions

Ideas for future versions (not promises):

- Visual campaign editor
- In-game scripting language
- More action functions
- Built-in quest system
- Inventory management system
- Dialogue tree editor

### Community Contributions

Isometry welcomes:
- Example campaigns
- Documentation improvements
- Bug reports
- Feature requests
- Asset packs
- Tutorial videos

## Philosophy in Practice

**Example: Why no inventory system?**

Isometry doesn't have a built-in inventory because:
1. **Different games need different systems** - Grid inventory? List inventory? Weight-based?
2. **Data-driven approach** - Use Resources for item counts
3. **Flexibility** - Campaign creators can design custom systems

**Example solution:**
```json
{
  "Resource": {
    "sword_count": {"default": 0, "min": 0, "max": 99},
    "potion_count": {"default": 3, "min": 0, "max": 10}
  }
}
```

Use Actions to transfer items, Menus for interaction.

## Closing Thoughts

Isometry's opinionated design isn't for everyone. If you need:
- Visual editor
- Different camera perspective
- General-purpose engine

...then Isometry might not be the right choice.

But if you want:
- Focused isometric RPG framework
- Data-driven campaign creation
- Built-in multiplayer
- Classic CRPG feel

...then Isometry provides a solid foundation.

**The goal:** Make creating isometric RPG campaigns as easy as creating D&D homebrew modules.

---

**Back to [Documentation Home](README.md)**
