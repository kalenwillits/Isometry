# Entity System Overview

Complete guide to Isometry's entity-based architecture.

## Table of Contents

- [What are Entities?](#what-are-entities)
- [KeyRef System](#keyref-system)
- [Entity Lifecycle](#entity-lifecycle)
- [Repository Pattern](#repository-pattern)
- [Entity Types Quick Reference](#entity-types-quick-reference)

## What are Entities?

**Entities** are the building blocks of Isometry campaigns. Everything in the game - characters, maps, skills, actions - is defined as an entity in JSON files.

### Data-Driven Design

Entities are **pure data** with no code:

```json
{
  "Actor": {
    "warrior": {
      "name": "Brave Warrior",
      "sprite": "warrior_sprite",
      "base": 32,
      "speed": 200.0
    }
  }
}
```

The game engine reads this data and creates runtime objects.

### Entity Types

Isometry provides **30 entity types**:

| Category | Entity Types |
|----------|--------------|
| **Core** | Main, Map, Actor |
| **Actions** | Action, Condition, Parameter |
| **Resources** | Resource, Measure |
| **Skills** | Skill |
| **AI** | Strategy, Behavior, Trigger, Timer |
| **Visual** | Sprite, Animation, AnimationSet |
| **Terrain** | TileSet, TileMap, Tile, Layer, Floor |
| **Geometry** | Vertex, Polygon |
| **Audio** | Sound, Parallax |
| **UI** | Menu, Plate, Waypoint, Group, Deployment |

## KeyRef System

### What is a KeyRef?

A **KeyRef** is a reference to another entity using its key:

```json
{
  "Actor": {
    "warrior": {
      "sprite": "warrior_sprite"   // KeyRef to Sprite entity
    }
  },
  "Sprite": {
    "warrior_sprite": {
      "texture": "assets/sprites/warrior.png"
    }
  }
}
```

**Think of it like a pointer or foreign key.**

### KeyRefArray

A **KeyRefArray** is an array of references:

```json
{
  "Actor": {
    "warrior": {
      "skills": ["attack", "defend", "heal"]   // KeyRefArray to Skill entities
    }
  },
  "Skill": {
    "attack": { "name": "Attack" },
    "defend": { "name": "Defend" },
    "heal": { "name": "Heal" }
  }
}
```

### How KeyRefs Work

**At load time:**
1. All entities are loaded from JSON
2. KeyRefs are stored as strings
3. Entities are added to the Repository

**At runtime:**
1. Code calls `keyref.lookup()`
2. Repository finds the referenced entity
3. Returns the actual entity object

**Example:**
```gdscript
# In GDScript (engine code)
var actor_ent = Repo.select("warrior")
var sprite_ent = actor_ent.sprite.lookup()  // Resolves "warrior_sprite" → Sprite entity
var texture_path = sprite_ent.texture        // "assets/sprites/warrior.png"
```

### Validation

KeyRefs are validated during campaign loading:

**Valid:**
```json
{
  "Actor": {
    "warrior": {
      "sprite": "warrior_sprite"   // ✓ References existing Sprite
    }
  },
  "Sprite": {
    "warrior_sprite": { ... }
  }
}
```

**Invalid:**
```json
{
  "Actor": {
    "warrior": {
      "sprite": "missing_sprite"   // ✗ ERROR: Sprite 'missing_sprite' not found
    }
  }
}
```

## Entity Lifecycle

### Loading Phase

```
1. Campaign ZIP opened
         │
         ▼
2. All JSON files read and merged
         │
         ▼
3. Campaign validated (4 phases)
         │
         ▼
4. For each entity:
   - Entity object created
   - Fields populated from JSON
   - Added to Repository as child node
         │
         ▼
5. Main entity loaded
   - Starting map built
   - Player actor spawned
```

### Querying Entities

**By Key:**
```gdscript
var actor_ent = Repo.select("warrior")
```

**By Tag:**
```gdscript
var all_actors = Repo.query([Group.ACTOR_ENTITY])
var all_maps = Repo.query([Group.MAP_ENTITY])
```

**KeyRef Lookup:**
```gdscript
var sprite_ent = actor_ent.sprite.lookup()
```

### Usage in Scenes

Entities are data containers. Runtime scenes (Actor, Map) use entity data to build themselves:

```gdscript
# Pseudocode: Building an Actor scene from entity data
func build_actor(actor_key: String) -> Actor:
    var actor_ent = Repo.select(actor_key)
    var sprite_ent = actor_ent.sprite.lookup()

    var actor_scene = Actor.new()
    actor_scene.display_name = actor_ent.name
    actor_scene.base_size = actor_ent.base
    actor_scene.speed = actor_ent.speed
    actor_scene.sprite_texture = load(sprite_ent.texture)

    return actor_scene
```

## Repository Pattern

### The Repo Singleton

All entities are stored in the **Repo** autoload singleton:

```
Repo (Node)
├── Main Entity (Node)
├── Actor Entity (Node)
│   ├── warrior
│   ├── mage
│   └── archer
├── Map Entity (Node)
│   ├── town
│   └── dungeon
├── Sprite Entity (Node)
│   ├── warrior_sprite
│   └── mage_sprite
└── ...
```

### Accessing Entities

**Select by key:**
```gdscript
var main_ent = Repo.select(Group.MAIN_ENTITY)
var warrior = Repo.select("warrior")
```

**Query by type:**
```gdscript
var all_actors = Repo.query([Group.ACTOR_ENTITY])
for actor_ent in all_actors:
    print(actor_ent.name)
```

**Query by multiple tags:**
```gdscript
var tagged_entities = Repo.query(["tag1", "tag2"])
```

## Entity Types Quick Reference

### Core Entities

| Entity | Purpose | Key Fields |
|--------|---------|------------|
| **[Main](core-entities.md#main-entity)** | Campaign entry point | actor, map, notes |
| **[Map](core-entities.md#map-entity)** | Game levels | tilemap, spawn, deployments |
| **[Actor](core-entities.md#actor-entity)** | Characters & NPCs | sprite, base, speed, skills, resources |

### Action System

| Entity | Purpose | Key Fields |
|--------|---------|------------|
| **[Action](action-system.md#action-entity)** | Executable behaviors | do, parameters, if, then, else |
| **[Condition](action-system.md#condition-entity)** | Boolean comparisons | left, operator, right |
| **[Parameter](action-system.md#parameter-entity)** | Action parameters | name, value |

### Resources & Stats

| Entity | Purpose | Key Fields |
|--------|---------|------------|
| **[Resource](resources.md#resource-entity)** | Trackable values | name, default, min, max |
| **[Measure](resources.md#measure-entity)** | Calculated values | expression, icon |

### Skills

| Entity | Purpose | Key Fields |
|--------|---------|------------|
| **[Skill](skills.md#skill-entity)** | Player abilities | start, end, icon, charge |

### AI System

| Entity | Purpose | Key Fields |
|--------|---------|------------|
| **[Strategy](ai-system.md#strategy-entity)** | AI decision-making | behaviors |
| **[Behavior](ai-system.md#behavior-entity)** | Goal-action pairs | goals, action |
| **[Trigger](ai-system.md#trigger-entity)** | Resource monitors | resource, action |
| **[Timer](ai-system.md#timer-entity)** | Scheduled actions | total, interval, action |

### Visual System

| Entity | Purpose | Key Fields |
|--------|---------|------------|
| **[Sprite](visual-entities.md#sprite-entity)** | Visual config | texture, size, animation_set |
| **[Animation](visual-entities.md#animation-entity)** | 8-directional frames | N, NE, E, SE, S, SW, W, NW |
| **[AnimationSet](visual-entities.md#animationset-entity)** | Animation collection | animations |

### Terrain System

| Entity | Purpose | Key Fields |
|--------|---------|------------|
| **[TileSet](terrain.md#tileset-entity)** | Tile collection | texture, columns, tiles |
| **[TileMap](terrain.md#tilemap-entity)** | Map grid | tileset, layers |
| **[Tile](terrain.md#tile-entity)** | Single tile | symbol, navigation, obstacle |
| **[Layer](terrain.md#layer-entity)** | Tile data | source, ysort |
| **[Floor](terrain.md#floor-entity)** | Floor texture | location, texture |

### Geometry

| Entity | Purpose | Key Fields |
|--------|---------|------------|
| **[Vertex](geometry.md#vertex-entity)** | 2D coordinate | x, y |
| **[Polygon](geometry.md#polygon-entity)** | Shape | vertices |

### Audio

| Entity | Purpose | Key Fields |
|--------|---------|------------|
| **[Sound](audio.md#sound-entity)** | Audio playback | source, scale, loop |
| **[Parallax](audio.md#parallax-entity)** | Background layer | texture, effect |

### UI System

| Entity | Purpose | Key Fields |
|--------|---------|------------|
| **[Menu](ui-entities.md#menu-entity)** | Action menu | actions |
| **[Plate](ui-entities.md#plate-entity)** | Text display | title, text |
| **[Waypoint](ui-entities.md#waypoint-entity)** | Fast-travel point | location, map |
| **[Group](ui-entities.md#group-entity)** | Faction/team | color |
| **[Deployment](ui-entities.md#deployment-entity)** | Actor placement | actor, location |

## Field Types Reference

### Standard Field Types

| Type | JSON Example | GDScript Type | Description |
|------|--------------|---------------|-------------|
| `String` | `"value"` | `String` | Text |
| `Int` | `42` | `int` | Integer number |
| `Float` | `3.14` | `float` | Decimal number |
| `Bool` | `true` | `bool` | Boolean |
| `Array` | `[1, 2, 3]` | `Array` | List of values |

### Reference Field Types

| Type | JSON Example | Description |
|------|--------------|-------------|
| `KeyRef` | `"entity_key"` | Reference to single entity |
| `KeyRefArray` | `["key1", "key2"]` | Reference to multiple entities |

### Dice Expression Fields

Some fields accept **dice notation** strings:

```json
{
  "Timer": {
    "poison": {
      "interval": "2d6+3"   // Dice expression
    }
  }
}
```

See [Dice Notation](../appendix/dice-notation.md) for syntax.

## Entity Tags

Each entity type has a corresponding tag (Godot group):

```gdscript
Group.MAIN_ENTITY         # "main-entity"
Group.ACTOR_ENTITY        # "actor-entity"
Group.MAP_ENTITY          # "map-entity"
Group.ACTION_ENTITY       # "action-entity"
// ... etc
```

Tags are used for querying entities:

```gdscript
var all_actors = Repo.query([Group.ACTOR_ENTITY])
```

## Reserved Keywords

GDScript has reserved keywords that can't be used as field names. Isometry aliases these:

| JSON Field | GDScript Property | Example |
|------------|-------------------|---------|
| `name` | `name_` | `actor_ent.name_` |
| `min` | `min_` | `resource_ent.min_` |
| `max` | `max_` | `resource_ent.max_` |
| `if` | `if_` | `action_ent.if_` |
| `else` | `else_` | `action_ent.else_` |
| `range` | `range_` | (if used) |
| `floor` | `floor_` | `floor_ent.floor_` |

**In JSON, use the original name:**
```json
{
  "Actor": {
    "warrior": {
      "name": "Warrior"   // Use "name", not "name_"
    }
  }
}
```

## Next Steps

**Learn about specific entity types:**
- [Core Entities (Main, Map, Actor)](core-entities.md)
- [Action System](action-system.md)
- [Resources & Measures](resources.md)
- [Skills](skills.md)
- [AI System](ai-system.md)
- [Visual Entities](visual-entities.md)
- [Terrain System](terrain.md)
- [Geometry](geometry.md)
- [Audio](audio.md)
- [UI Entities](ui-entities.md)

**Or explore:**
- [Action Reference](../actions/reference.md) - All 69 actions
- [Campaign Basics](../campaign-basics.md) - Creating campaigns
- [Examples](../examples/minimal-campaign.md) - Tutorials

---

**Back to [Documentation Home](../README.md)**
