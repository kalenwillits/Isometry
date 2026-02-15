# Campaign Basics

Fundamental guide to creating Isometry campaigns.

## Table of Contents

- [Campaign Architecture](#campaign-architecture)
- [JSON Entity Pattern](#json-entity-pattern)
- [Directory Organization](#directory-organization)
- [The Main Entity](#the-main-entity)
- [Campaign Validation](#campaign-validation)
- [Creating Your First Campaign](#creating-your-first-campaign)

## Campaign Architecture

### What is a Campaign?

A **campaign** in Isometry is a complete game package containing:
- **Entity definitions** (JSON files)
- **Assets** (sprites, tilesets, audio)
- **Game logic** (actions, AI behaviors, triggers)

Campaigns are 100% data-driven - no programming required.

### ZIP Archive Format

All campaigns are packaged as **ZIP archives**:

```
my_campaign.zip
└── my_campaign/          # Root folder (must match ZIP name)
    ├── actors.json       # Actor entity definitions
    ├── maps.json         # Map entity definitions
    ├── actions.json      # Action entity definitions
    ├── skills.json       # Skill entity definitions
    ├── sprites/
    │   ├── warrior.png
    │   └── mage.png
    ├── tilesets/
    │   └── dungeon.png
    ├── audio/
    │   └── battle.ogg
    └── ...
```

**Important:**
- ZIP must contain a single root folder
- Root folder name should match campaign name
- All paths in JSON are relative to root folder
- File extensions are case-sensitive

### Campaign Lifecycle

```
1. Create JSON files    ─►  2. Add assets (PNG, OGG)
         │                           │
         ▼                           ▼
3. Package as ZIP       ◄──  4. Validate campaign
         │
         ▼
5. Distribute to players
```

## JSON Entity Pattern

### Type:Key:Content Structure

All entity JSON files follow this pattern:

```json
{
  "EntityType": {
    "entity_key": {
      "field1": "value1",
      "field2": "value2"
    }
  }
}
```

**Components:**
- **EntityType** - The type of entity (Actor, Map, Action, etc.)
- **entity_key** - Unique identifier for this specific entity
- **Content** - Field-value pairs defining the entity

### Example: Actor Entity

```json
{
  "Actor": {
    "hero_warrior": {
      "name": "Brave Warrior",
      "sprite": "warrior_sprite",
      "base": 32,
      "speed": 200.0,
      "hitbox": "warrior_hitbox",
      "skills": ["attack", "defend", "heal"]
    }
  }
}
```

**Breaking it down:**
- **Type:** `Actor`
- **Key:** `hero_warrior`
- **Fields:** name, sprite, base, speed, hitbox, skills

### Multiple Entities in One File

You can define multiple entities in a single file:

```json
{
  "Actor": {
    "warrior": { "name": "Warrior", "base": 32 },
    "mage": { "name": "Mage", "base": 28 },
    "archer": { "name": "Archer", "base": 30 }
  }
}
```

Or organize by entity type:

```json
{
  "Actor": {
    "hero": { "name": "Hero" }
  },
  "Map": {
    "town": { "name": "Town Square" }
  },
  "Skill": {
    "fireball": { "name": "Fireball" }
  }
}
```

### Multiple Files

Isometry merges all JSON files in the ZIP:

```
campaign/
├── core.json        # Main, starting actor, map
├── actors.json      # All actor definitions
├── maps.json        # All map definitions
├── actions.json     # All action definitions
├── skills.json      # All skill definitions
└── resources.json   # All resource definitions
```

**All files are merged into a single entity dictionary.**

### Field Types

**Primitive Types:**
- `String` - Text: `"value"`
- `Int` - Integer: `42`
- `Float` - Decimal: `3.14` (must include decimal point — `3` is rejected for Float fields)
- `Bool` - Boolean: `true` or `false`

> **Type Strictness:** The validator accepts `3.0` for an Int field (whole-number float → int), but does **not** accept `3` for a Float field. Always include a decimal point for Float values (e.g., `200.0` not `200`).

**Reference Types:**
- `KeyRef` - Reference to another entity: `"entity_key"`
- `KeyRefArray` - Array of references: `["key1", "key2", "key3"]`

**Example:**

```json
{
  "Actor": {
    "warrior": {
      "name": "Warrior",              // String
      "base": 32,                      // Int
      "speed": 200.0,                  // Float
      "sprite": "warrior_sprite",      // KeyRef to Sprite entity
      "skills": ["attack", "defend"],  // KeyRefArray to Skill entities
      "on_touch": "counter_attack"     // KeyRef to Action entity
    }
  }
}
```

## Directory Organization

### Recommended Structure

```
my_campaign/
├── core/
│   ├── main.json          # Main entity
│   ├── resources.json     # Resource entities
│   └── groups.json        # Group entities
├── actors/
│   ├── heroes.json        # Player characters
│   ├── enemies.json       # Hostile NPCs
│   └── npcs.json          # Friendly NPCs
├── maps/
│   ├── town.json          # Town map
│   ├── dungeon.json       # Dungeon map
│   └── forest.json        # Forest map
├── combat/
│   ├── skills.json        # Skill entities
│   ├── actions.json       # Action entities
│   └── ai.json            # Strategy/Behavior entities
├── assets/
│   ├── sprites/
│   │   ├── characters/
│   │   │   ├── warrior.png
│   │   │   └── mage.png
│   │   └── enemies/
│   │       └── goblin.png
│   ├── tilesets/
│   │   ├── town_tileset.png
│   │   └── dungeon_tileset.png
│   ├── icons/
│   │   ├── attack_icon.png
│   │   └── defend_icon.png
│   └── audio/
│       ├── music/
│       │   └── battle.ogg
│       └── sfx/
│           └── sword_slash.ogg
└── ui/
    ├── menus.json         # Menu entities
    └── plates.json        # Plate entities (text displays)
```

### Naming Conventions

**Entity Keys:**
- Use `snake_case`: `hero_warrior`, `dungeon_level_1`
- Be descriptive: `fireball_skill` not `skill1`
- Use prefixes for organization: `enemy_goblin`, `npc_merchant`

**File Names:**
- Use lowercase: `actors.json` not `Actors.json`
- Group related entities: `combat_skills.json`, `town_npcs.json`

**Asset Paths:**
- Relative to campaign root: `assets/sprites/warrior.png`
- Use subdirectories: `assets/sprites/enemies/goblin.png`
- Consistent naming: `warrior_idle.png`, `warrior_attack.png`

## The Main Entity

### Required Entity

Every campaign **must** have exactly **one** Main entity. This defines the starting state.

### Main Entity Structure

```json
{
  "Main": {
    "campaign_start": {
      "actor": "hero_warrior",
      "map": "town_square",
      "notes": "A brave warrior begins their adventure in the town square."
    }
  }
}
```

**Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `actor` | KeyRef | Yes | Starting actor for the player |
| `map` | KeyRef | Yes | Starting map where the game begins |
| `notes` | String | No | Campaign description/notes |

### Example: Complete Main Entity

```json
{
  "Main": {
    "epic_adventure_start": {
      "actor": "chosen_hero",
      "map": "village_square",
      "notes": "An epic fantasy adventure begins in a peaceful village. The hero must discover their destiny and save the kingdom from darkness."
    }
  },
  "Actor": {
    "chosen_hero": {
      "name": "The Chosen One",
      "sprite": "hero_sprite",
      "base": 32,
      "speed": 200.0,
      "bearing": 180,
      "perception": 200,
      "skills": ["basic_attack", "heal"],
      "resources": ["health", "mana"]
    }
  },
  "Map": {
    "village_square": {
      "name": "Village Square",
      "tilemap": "village_tilemap",
      "spawn": "village_spawn_point"
    }
  }
}
```

### What Happens at Launch

When Isometry loads your campaign:

1. Reads the Main entity
2. Loads the starting `map`
3. Spawns the player's `actor` at the map's spawn point
4. Initializes resources, skills, and AI behaviors
5. Game begins!

> **Save File Override:** If the player has a save file from a previous session, saved `actor` and `map` values are merged into the spawn data. If the campaign has changed (e.g., entity keys were renamed), stale save data can cause the wrong actor or map to load. Players may need to delete their save file in the data directory to resolve this.

## Campaign Validation

### Four-Phase Validation

Isometry validates campaigns using a four-phase system:

#### Phase 1: Schema Validation

Checks that all entities have required fields and correct types.

**Example error:**
```
ERROR: Actor 'hero_warrior' missing required field 'sprite'
ERROR: Skill 'fireball' field 'charge' must be Int, got String
```

**Fix:** Add missing fields or correct types

#### Phase 2: Cross-Reference Validation

Ensures all KeyRefs point to existing entities.

**Example error:**
```
ERROR: Actor 'hero_warrior' references sprite 'missing_sprite' which doesn't exist
ERROR: Map 'dungeon' references tilemap 'missing_tilemap' which doesn't exist
```

**Fix:** Create the referenced entity or fix the key

#### Phase 3: Asset Validation

Verifies all asset paths exist in the ZIP archive.

**Example error:**
```
ERROR: Sprite 'warrior_sprite' references texture 'assets/sprites/warrior.png' which doesn't exist in archive
ERROR: Sound 'battle_music' references source 'audio/battle.ogg' which doesn't exist
```

**Fix:** Add the asset file to the ZIP or fix the path

#### Phase 4: Dice Expression Validation

Checks that dice notation strings are valid.

**Example error:**
```
ERROR: Timer 'poison_damage' field 'interval' has invalid dice expression '2dd6'
ERROR: Action parameter 'damage' value '1d20+abc' is not a valid dice expression
```

**Fix:** Correct the dice notation syntax

### Main Entity Validation

**Required:** Exactly **one** Main entity

**Errors:**
```
ERROR: Campaign requires exactly one Main entity (found 0)
ERROR: Campaign has duplicate Main entities (found 3)
```

### Duplicate Key Validation

**Rule:** Entity keys must be unique **across all entity types**

**Bad:**
```json
{
  "Actor": {
    "warrior": { ... }
  },
  "Sprite": {
    "warrior": { ... }   // ERROR: Duplicate key 'warrior'
  }
}
```

**Good:**
```json
{
  "Actor": {
    "warrior_actor": { ... }
  },
  "Sprite": {
    "warrior_sprite": { ... }   // OK: Unique key
  }
}
```

### Action Function Validation

**Rule:** Action `do` field must reference a valid function

**Valid functions:** Must match one of the 62 available action functions

**Error:**
```json
{
  "Action": {
    "my_action": {
      "do": "invalid_function_name"   // ERROR: No such function
    }
  }
}
```

**Fix:** Use a valid action function:
```json
{
  "Action": {
    "my_action": {
      "do": "plus_resource_self"   // OK: Valid function
    }
  }
}
```

### Running Validation

**Automatic:** Validation runs when loading a campaign

**Manual:** Use validation tools (if provided by Isometry build)

**Log Output:**

```bash
./isometry --campaign=my_campaign --network=none

Starting campaign validation...
Phase 1: Schema validation
Phase 2: Cross-reference validation
Phase 3: Asset validation
Phase 4: Dice expression validation
Campaign validation passed
```

**With Errors:**

```bash
ERROR: Actor 'hero' missing required field 'sprite'
ERROR: Map 'town' references spawn 'missing_spawn' which doesn't exist
ERROR: Sprite 'hero_sprite' references texture 'missing.png' not in archive
Campaign validation failed with 3 error(s)
```

### Common Validation Errors

#### Missing Required Field

```
ERROR: Actor 'hero' missing required field 'sprite'
```

**Fix:** Add the required field:
```json
{
  "Actor": {
    "hero": {
      "sprite": "hero_sprite",  // Add this
      "base": 32
    }
  }
}
```

#### Invalid KeyRef

```
ERROR: Actor 'hero' field 'sprite' references 'missing_sprite' which doesn't exist
```

**Fix:** Create the referenced entity:
```json
{
  "Sprite": {
    "missing_sprite": {
      "texture": "assets/sprites/hero.png",
      "size": "size_32x32",
      "animation_set": "hero_animations"
    }
  }
}
```

#### Asset Not Found

```
ERROR: Sprite 'hero_sprite' texture 'wrong/path.png' not found in archive
```

**Fix:** Correct the path or add the file:
- Add `wrong/path.png` to ZIP, or
- Change path to `assets/sprites/hero.png`

#### Invalid Type

```
ERROR: Actor 'hero' field 'base' must be Int, got String "32"
```

**Fix:** Remove quotes:
```json
{
  "Actor": {
    "hero": {
      "base": 32  // Not "32"
    }
  }
}
```

## Creating Your First Campaign

### Step-by-Step Minimal Campaign

#### 1. Create Directory Structure

```bash
mkdir -p my_campaign/assets/sprites
cd my_campaign
```

#### 2. Create Main Entity (main.json)

```json
{
  "Main": {
    "start": {
      "actor": "player",
      "map": "test_map",
      "notes": "My first campaign"
    }
  }
}
```

#### 3. Create Actor (actors.json)

```json
{
  "Actor": {
    "player": {
      "name": "Hero",
      "sprite": "player_sprite",
      "base": 32,
      "speed": 200.0,
      "bearing": 180,
      "perception": 200,
      "hitbox": "player_hitbox",
      "skills": [],
      "resources": ["health"]
    }
  }
}
```

#### 4. Create Sprite (sprites.json)

```json
{
  "Sprite": {
    "player_sprite": {
      "texture": "assets/sprites/player.png",
      "size": "size_32x32",
      "margin": "margin_0",
      "animation_set": "player_animations"
    }
  },
  "AnimationSet": {
    "player_animations": {
      "animations": ["idle"]
    }
  },
  "Animation": {
    "idle": {
      "N": [0], "NE": [0], "E": [0], "SE": [0],
      "S": [0], "SW": [0], "W": [0], "NW": [0],
      "loop": true
    }
  }
}
```

#### 5. Create Geometry (geometry.json)

```json
{
  "Vertex": {
    "size_32x32": { "x": 32, "y": 32 },
    "margin_0": { "x": 0, "y": 0 },
    "spawn_point": { "x": 400, "y": 300 },
    "hitbox_tl": { "x": -16, "y": -16 },
    "hitbox_tr": { "x": 16, "y": -16 },
    "hitbox_br": { "x": 16, "y": 16 },
    "hitbox_bl": { "x": -16, "y": 16 }
  },
  "Polygon": {
    "player_hitbox": {
      "vertices": ["hitbox_tl", "hitbox_tr", "hitbox_br", "hitbox_bl"]
    }
  }
}
```

#### 6. Create Resources (resources.json)

```json
{
  "Resource": {
    "health": {
      "name": "Health",
      "default": 100,
      "min": 0,
      "max": 100,
      "icon": "",
      "reveal": 0
    }
  }
}
```

#### 7. Create Map (maps.json)

```json
{
  "Map": {
    "test_map": {
      "name": "Test Map",
      "tilemap": "test_tilemap",
      "spawn": "spawn_point",
      "deployments": []
    }
  },
  "TileMap": {
    "test_tilemap": {
      "tileset": "grass_tileset",
      "layers": ["grass_layer"]
    }
  },
  "TileSet": {
    "grass_tileset": {
      "texture": "assets/sprites/grass.png",
      "columns": 1,
      "tiles": ["grass_tile"]
    }
  },
  "Tile": {
    "grass_tile": {
      "symbol": "G",
      "index": 0,
      "origin": 0,
      "navigation": true,
      "obstacle": false,
      "ghost": false
    }
  },
  "Layer": {
    "grass_layer": {
      "source": "/my_campaign_map/layer0",
      "ysort": false
    }
  }
}
```

The `source` field is a **file path** (relative to the campaign root) pointing to a text grid file. Create the layer file at `my_campaign_map/layer0`:

```
GGGGGGGGG
GGGGGGGGG
GGGGGGGGG
```

Each character maps to a tile symbol defined in your TileSet. Spaces mean no tile.

#### 8. Add Assets

Create placeholder sprites:

```bash
# Create a 32x32 player sprite (use any image editor)
# Save as: assets/sprites/player.png

# Create a 32x32 grass tile
# Save as: assets/sprites/grass.png
```

Or use ImageMagick to create test images:

```bash
# Red player sprite
convert -size 32x32 xc:red assets/sprites/player.png

# Green grass tile
convert -size 32x32 xc:green assets/sprites/grass.png
```

#### 9. Package as ZIP

```bash
cd ..
zip -r my_campaign.zip my_campaign/
```

#### 10. Test

```bash
./isometry --campaign=my_campaign --network=none
```

You should see:
- A green grass terrain
- A red square (your character)
- Ability to click to move

### Next Steps

Now that you have a working campaign:

1. **Add skills** - See [Skills Entity](entities/skills.md)
2. **Add actions** - See [Action System](entities/action-system.md)
3. **Add more maps** - Create multiple maps with transitions
4. **Add NPCs** - Create Deployment entities for actor placements
5. **Add AI behaviors** - See [AI System](entities/ai-system.md)

---

**Next:** [Entity System](entities/README.md) | [Back to Home](README.md)
