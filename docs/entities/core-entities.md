# Core Entities

Documentation for Main, Map, and Actor entities - the foundation of every campaign.

## Table of Contents

- [Main Entity](#main-entity)
- [Map Entity](#map-entity)
- [Actor Entity](#actor-entity)

## Main Entity

### Purpose

The **Main** entity defines the campaign's entry point and starting state. Every campaign must have exactly one Main entity.

### Tags

`Group.MAIN_ENTITY`

### File

`/home/kalen/Dev/isometry/app/entities/Main.gd`

### Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `actor` | KeyRef | Yes | - | Starting actor for the player |
| `map` | KeyRef | Yes | - | Starting map where the campaign begins |
| `notes` | String | No | `""` | Campaign description or notes |

### Field Details

#### actor
- **Type**: KeyRef to Actor entity
- **Required**: Yes
- **Description**: The player's starting character. This Actor will be spawned when the campaign loads.
- **Example**: `"hero_warrior"`, `"chosen_one"`, `"player_character"`

#### map
- **Type**: KeyRef to Map entity
- **Required**: Yes
- **Description**: The map where the campaign begins. The player's actor will spawn at this map's spawn point.
- **Example**: `"town_square"`, `"tutorial_area"`, `"starting_village"`

#### notes
- **Type**: String
- **Required**: No
- **Default**: `""` (empty string)
- **Description**: Optional campaign description, lore, or development notes. Not displayed to players by default.
- **Example**: `"An epic fantasy adventure to save the kingdom"`

### JSON Example

```json
{
  "Main": {
    "campaign_start": {
      "actor": "hero",
      "map": "village_square",
      "notes": "A humble farmer discovers their destiny to become a legendary hero."
    }
  }
}
```

### Complete Example with Dependencies

```json
{
  "Main": {
    "epic_quest_start": {
      "actor": "chosen_hero",
      "map": "peaceful_village",
      "notes": "Your journey begins in a peaceful village, unaware of the darkness approaching."
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
      "skills": ["basic_attack"],
      "resources": ["health", "mana"]
    }
  },
  "Map": {
    "peaceful_village": {
      "name": "Peaceful Village",
      "tilemap": "village_tilemap",
      "spawn": "village_spawn_point",
      "deployments": ["village_elder", "town_guard"]
    }
  }
}
```

### Validation Rules

- **Exactly one Main entity required**: Campaigns must have precisely one Main entity
- **No duplicate Main entities**: Only one Main entity allowed
- **Valid references**: Both `actor` and `map` must reference existing entities

### Common Patterns

#### Single-Player Campaign
```json
{
  "Main": {
    "start": {
      "actor": "solo_hero",
      "map": "starting_area",
      "notes": "Single-player adventure"
    }
  }
}
```

#### Multiplayer Campaign
```json
{
  "Main": {
    "start": {
      "actor": "default_character",
      "map": "spawn_lobby",
      "notes": "Multiplayer dungeon crawler. Players spawn in the lobby."
    }
  }
}
```

Note: In multiplayer, all players spawn as the same actor entity initially, but their save files differentiate them.

### Related Entities

- **Actor** - Referenced by `actor` field
- **Map** - Referenced by `map` field

---

## Map Entity

### Purpose

The **Map** entity defines a game level containing terrain, spawn points, actors, and environmental elements.

### Tags

`Group.MAP_ENTITY`

### File

`/home/kalen/Dev/isometry/app/entities/Map.gd`

### Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `name` | String | Yes | - | Human-readable map name |
| `tilemap` | KeyRef | Yes | - | TileMap entity defining the terrain |
| `spawn` | KeyRef | Yes | - | Vertex entity for player spawn location |
| `deployments` | KeyRefArray | No | `[]` | Actor deployments (NPCs) on this map |
| `floor` | KeyRefArray | No | `[]` | Floor textures at specific locations |
| `background` | KeyRefArray | No | `[]` | Parallax background layers |
| `audio` | KeyRefArray | No | `[]` | Background audio/music |

### Field Details

#### name
- **Type**: String
- **Required**: Yes
- **Description**: Display name for the map shown in UI elements
- **Example**: `"Town Square"`, `"Dungeon Level 1"`, `"Forest Path"`

#### tilemap
- **Type**: KeyRef to TileMap entity
- **Required**: Yes
- **Description**: The tilemap defining the terrain grid and collision
- **See**: [TileMap Entity](terrain.md#tilemap-entity)

#### spawn
- **Type**: KeyRef to Vertex entity
- **Required**: Yes
- **Description**: The (x, y) coordinate where players spawn when entering this map
- **Example**: `"town_center_spawn"`, `"dungeon_entrance"`

#### deployments
- **Type**: KeyRefArray to Deployment entities
- **Required**: No
- **Default**: `[]` (empty array)
- **Description**: NPCs and actors placed on the map at specific locations
- **See**: [Deployment Entity](ui-entities.md#deployment-entity)

#### floor
- **Type**: KeyRefArray to Floor entities
- **Required**: No
- **Default**: `[]` (empty array)
- **Description**: Decorative floor textures placed at specific coordinates
- **See**: [Floor Entity](terrain.md#floor-entity)
- **Use case**: Carpets, pools of water, blood stains, etc.

#### background
- **Type**: KeyRefArray to Parallax entities
- **Required**: No
- **Default**: `[]` (empty array)
- **Description**: Parallax scrolling background layers for depth
- **See**: [Parallax Entity](audio.md#parallax-entity)
- **Use case**: Distant mountains, clouds, sky, stars

#### audio
- **Type**: KeyRefArray to Sound entities
- **Required**: No
- **Default**: `[]` (empty array)
- **Description**: Looping background music or ambient sounds
- **See**: [Sound Entity](audio.md#sound-entity)
- **Use case**: Background music, ambient forest sounds, dungeon ambiance

### JSON Example

```json
{
  "Map": {
    "forest_clearing": {
      "name": "Forest Clearing",
      "tilemap": "forest_tilemap",
      "spawn": "clearing_center",
      "deployments": ["friendly_deer", "hostile_wolf"],
      "floor": [],
      "background": ["forest_bg_layer1", "forest_bg_layer2"],
      "audio": ["forest_ambiance", "bird_chirping"]
    }
  }
}
```

### Complete Example

```json
{
  "Map": {
    "dungeon_entrance": {
      "name": "Dungeon Entrance Hall",
      "tilemap": "dungeon_tilemap",
      "spawn": "entrance_spawn",
      "deployments": ["dungeon_guard_1", "dungeon_guard_2", "treasure_chest"],
      "floor": ["bloodstain_1", "torch_light_1", "torch_light_2"],
      "background": ["dungeon_background"],
      "audio": ["dungeon_ambiance"]
    }
  },
  "TileMap": {
    "dungeon_tilemap": {
      "tileset": "stone_tileset",
      "layers": ["dungeon_floor", "dungeon_walls"]
    }
  },
  "Vertex": {
    "entrance_spawn": { "x": 400, "y": 300 }
  },
  "Deployment": {
    "dungeon_guard_1": {
      "actor": "skeleton_warrior",
      "location": "guard_pos_1"
    },
    "dungeon_guard_2": {
      "actor": "skeleton_warrior",
      "location": "guard_pos_2"
    }
  },
  "Sound": {
    "dungeon_ambiance": {
      "source": "assets/audio/dungeon_amb.ogg",
      "scale": "1.0",
      "loop": true
    }
  }
}
```

### Common Patterns

#### Minimal Map (No NPCs or Decoration)
```json
{
  "Map": {
    "simple_map": {
      "name": "Simple Test Map",
      "tilemap": "grass_tilemap",
      "spawn": "center_spawn",
      "deployments": [],
      "floor": [],
      "background": [],
      "audio": []
    }
  }
}
```

#### Town Map with NPCs
```json
{
  "Map": {
    "town": {
      "name": "Riverdale Town",
      "tilemap": "town_tilemap",
      "spawn": "town_gate",
      "deployments": [
        "merchant", "blacksmith", "town_guard_1", 
        "town_guard_2", "quest_giver", "children_playing"
      ],
      "floor": ["fountain_water"],
      "background": ["town_skyline"],
      "audio": ["town_music", "marketplace_chatter"]
    }
  }
}
```

#### Dungeon Boss Room
```json
{
  "Map": {
    "boss_chamber": {
      "name": "Chamber of the Demon Lord",
      "tilemap": "boss_room_tilemap",
      "spawn": "entrance_door",
      "deployments": ["demon_lord_boss", "demon_minion_1", "demon_minion_2"],
      "floor": ["ritual_circle", "bloodstains"],
      "background": ["hell_portal_bg"],
      "audio": ["boss_music", "demonic_chanting"]
    }
  }
}
```

### Map Transitions

Actors can transition between maps using actions:

```json
{
  "Action": {
    "enter_dungeon": {
      "name": "Enter Dungeon",
      "do": "change_map_self",
      "parameters": [
        { "Parameter": { "map_param": { "name": "map", "value": "dungeon_level_1" } } },
        { "Parameter": { "loc_param": { "name": "location", "value": "dungeon_spawn" } } }
      ]
    }
  }
}
```

See [change_map_self](../actions/reference.md#change_map_self) and [change_map_target](../actions/reference.md#change_map_target) actions.

### Related Entities

- **TileMap** - Terrain and collision grid
- **Deployment** - Actor placements
- **Floor** - Decorative textures
- **Parallax** - Background layers
- **Sound** - Audio tracks
- **Vertex** - Spawn point coordinate

---

## Actor Entity

### Purpose

The **Actor** entity represents all characters in the game - player-controlled, NPCs, and enemies. It defines visual appearance, stats, skills, behaviors, and event responses.

### Tags

`Group.ACTOR_ENTITY`

### File

`/home/kalen/Dev/isometry/app/entities/Actor.gd`

### Fields Overview

| Category | Fields |
|----------|--------|
| **Identity** | `name` |
| **Visual** | `sprite`, `base`, `hitbox`, `bearing` |
| **Movement** | `speed` |
| **Perception** | `perception`, `salience` |
| **Combat** | `skills`, `resources`, `measures` |
| **AI** | `strategy`, `triggers`, `timers` |
| **Social** | `group`, `menu`, `public`, `private` |
| **Events** | `on_touch`, `on_view`, `on_map_entered`, `on_map_exited` |

### All Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `name` | String | Yes | - | Display name |
| `sprite` | KeyRef | Yes | - | Visual representation |
| `base` | Int | Yes | - | Base circle size (pixels) |
| `hitbox` | KeyRef | Yes | - | Collision polygon |
| `speed` | Float | Yes | - | Movement speed (pixels/second) |
| `bearing` | Int | No | `0` | Facing direction (0-360°) |
| `perception` | Int | Yes | - | Vision range (pixels) |
| `salience` | Int | Yes | - | Detection difficulty |
| `skills` | KeyRefArray | No | `[]` | Available skills (max 9) |
| `resources` | KeyRefArray | No | `[]` | Resource values (HP, mana, etc.) |
| `measures` | KeyRefArray | No | `[]` | Calculated values |
| `public` | KeyRefArray | No | `[]` | Resources visible to others |
| `private` | KeyRefArray | No | `[]` | Resources visible only to self |
| `group` | KeyRef | No | `null` | Faction/team |
| `menu` | KeyRef | No | `null` | Interaction menu |
| `strategy` | KeyRef | No | `null` | AI behavior |
| `triggers` | KeyRefArray | No | `[]` | Resource change handlers |
| `timers` | KeyRefArray | No | `[]` | Scheduled actions |
| `on_touch` | KeyRef | No | `null` | Action when touched |
| `on_view` | KeyRef | No | `null` | Action when viewed |
| `on_map_entered` | KeyRef | No | `null` | Action on map entry |
| `on_map_exited` | KeyRef | No | `null` | Action on map exit |

### Field Details

#### name
- **Type**: String
- **Required**: Yes
- **Description**: Human-readable name displayed in UI, chat, and target plates
- **Example**: `"Brave Warrior"`, `"Goblin Scout"`, `"Village Elder"`

#### sprite
- **Type**: KeyRef to Sprite entity
- **Required**: Yes
- **Description**: Visual appearance with animations
- **See**: [Sprite Entity](visual-entities.md#sprite-entity)

#### base
- **Type**: Int (pixels)
- **Required**: Yes
- **Description**: Radius of the actor's circular base for isometric rendering
- **Common values**: 16 (small), 32 (medium), 48 (large), 64 (huge)
- **Use**: Determines selection circle size and rough collision area

#### hitbox
- **Type**: KeyRef to Polygon entity
- **Required**: Yes
- **Description**: Precise collision boundary
- **See**: [Polygon Entity](geometry.md#polygon-entity)
- **Tip**: Usually matches base size (e.g., 32x32 square polygon for base: 32)

#### speed
- **Type**: Float (pixels per second)
- **Required**: Yes
- **Description**: Movement speed
- **Common values**: 100 (slow), 200 (normal), 300 (fast), 400 (very fast)

#### bearing
- **Type**: Int (degrees: 0-360)
- **Required**: No
- **Default**: `0` (north)
- **Description**: Initial facing direction
- **Values**: 0=N, 45=NE, 90=E, 135=SE, 180=S, 225=SW, 270=W, 315=NW

#### perception
- **Type**: Int (pixels)
- **Required**: Yes
- **Description**: How far the actor can see other actors
- **Use**: Vision range for fog of war, detecting enemies, triggering `on_view` events
- **Common values**: 100 (short-sighted), 200 (normal), 400 (eagle-eyed)

#### salience
- **Type**: Int
- **Required**: Yes
- **Description**: How easy the actor is to detect (higher = more visible)
- **Use**: Stealth mechanics, NPC awareness
- **Common values**: 50 (hidden), 100 (normal), 200 (conspicuous)

#### skills
- **Type**: KeyRefArray to Skill entities
- **Required**: No
- **Default**: `[]`
- **Limit**: Maximum **9 skills** (bound to keys 1-9)
- **Description**: Available abilities
- **See**: [Skill Entity](skills.md#skill-entity)

#### resources
- **Type**: KeyRefArray to Resource entities
- **Required**: No
- **Default**: `[]`
- **Description**: Trackable values like health, mana, gold
- **See**: [Resource Entity](resources.md#resource-entity)
- **Note**: All Resource entities are automatically initialized on every actor

#### measures
- **Type**: KeyRefArray to Measure entities
- **Required**: No
- **Default**: `[]`
- **Description**: Calculated values (armor class, DPS, etc.)
- **See**: [Measure Entity](resources.md#measure-entity)

#### public
- **Type**: KeyRefArray to Resource entities
- **Required**: No
- **Default**: `[]`
- **Description**: Resources visible when other actors target this actor
- **Example**: `["health"]` - shows health bar when targeted

#### private
- **Type**: KeyRefArray to Resource entities
- **Required**: No
- **Default**: `[]`
- **Description**: Resources visible only on the actor's own UI
- **Example**: `["mana", "gold"]` - only the player sees their mana and gold

#### group
- **Type**: KeyRef to Group entity
- **Required**: No
- **Default**: `null`
- **Description**: Faction/team membership for outline color and targeting
- **See**: [Group Entity](ui-entities.md#group-entity)

#### menu
- **Type**: KeyRef to Menu entity
- **Required**: No
- **Default**: `null`
- **Description**: Right-click interaction menu
- **See**: [Menu Entity](ui-entities.md#menu-entity)

#### strategy
- **Type**: KeyRef to Strategy entity
- **Required**: No
- **Default**: `null`
- **Description**: AI decision-making behaviors
- **See**: [Strategy Entity](ai-system.md#strategy-entity)
- **Use**: NPCs and enemies

#### triggers
- **Type**: KeyRefArray to Trigger entities
- **Required**: No
- **Default**: `[]`
- **Description**: Monitors resources and executes actions when they change
- **See**: [Trigger Entity](ai-system.md#trigger-entity)
- **Example**: Execute action when health drops below 25%

#### timers
- **Type**: KeyRefArray to Timer entities
- **Required**: No
- **Default**: `[]`
- **Description**: Executes actions at intervals or after a duration
- **See**: [Timer Entity](ai-system.md#timer-entity)
- **Example**: Regenerate 5 health every 3 seconds

#### on_touch
- **Type**: KeyRef to Action entity
- **Required**: No
- **Default**: `null`
- **Description**: Action triggered when another actor touches this actor
- **Example**: Counter-attack, apply debuff, trigger dialogue

#### on_view
- **Type**: KeyRef to Action entity
- **Required**: No
- **Default**: `null`
- **Description**: Action triggered when another actor sees this actor
- **Example**: Aggro behavior, stealth detection warning

#### on_map_entered
- **Type**: KeyRef to Action entity
- **Required**: No
- **Default**: `null`
- **Description**: Action triggered when this actor enters a map
- **Example**: Play entrance cutscene, apply map buff

#### on_map_exited
- **Type**: KeyRef to Action entity
- **Required**: No
- **Default**: `null`
- **Description**: Action triggered when this actor leaves a map
- **Example**: Save progress, clear map-specific effects

### JSON Example - Basic Actor

```json
{
  "Actor": {
    "village_guard": {
      "name": "Village Guard",
      "sprite": "guard_sprite",
      "base": 32,
      "hitbox": "guard_hitbox",
      "speed": 180.0,
      "bearing": 90,
      "perception": 250,
      "salience": 100,
      "skills": ["sword_slash"],
      "resources": ["health", "stamina"],
      "public": ["health"],
      "private": [],
      "group": "town_guards"
    }
  }
}
```

### Complete Example - Player Character

```json
{
  "Actor": {
    "hero_mage": {
      "name": "Archmage Elara",
      "sprite": "mage_sprite",
      "base": 28,
      "hitbox": "mage_hitbox",
      "speed": 200.0,
      "bearing": 180,
      "perception": 300,
      "salience": 80,
      "skills": ["fireball", "ice_blast", "teleport", "heal", "mana_shield"],
      "resources": ["health", "mana", "experience"],
      "measures": ["spell_power"],
      "public": ["health", "mana"],
      "private": ["experience"],
      "group": "heroes",
      "menu": "mage_interaction_menu",
      "strategy": null,
      "triggers": ["low_health_warning"],
      "timers": ["mana_regen"],
      "on_touch": null,
      "on_view": null,
      "on_map_entered": "mage_entrance_effect",
      "on_map_exited": "save_progress"
    }
  }
}
```

### Complete Example - Enemy with AI

```json
{
  "Actor": {
    "goblin_warrior": {
      "name": "Goblin Warrior",
      "sprite": "goblin_sprite",
      "base": 24,
      "hitbox": "goblin_hitbox",
      "speed": 220.0,
      "bearing": 0,
      "perception": 180,
      "salience": 120,
      "skills": ["goblin_stab"],
      "resources": ["health"],
      "public": ["health"],
      "private": [],
      "group": "goblins",
      "menu": null,
      "strategy": "goblin_aggro_strategy",
      "triggers": ["goblin_death_trigger"],
      "timers": [],
      "on_touch": "goblin_melee_attack",
      "on_view": "goblin_shout",
      "on_map_entered": null,
      "on_map_exited": null
    }
  }
}
```

### Common Patterns

#### Merchant NPC
```json
{
  "Actor": {
    "merchant": {
      "name": "Traveling Merchant",
      "sprite": "merchant_sprite",
      "base": 32,
      "hitbox": "merchant_hitbox",
      "speed": 100.0,
      "perception": 150,
      "salience": 100,
      "skills": [],
      "resources": ["health", "gold"],
      "public": ["health"],
      "private": ["gold"],
      "group": "neutral",
      "menu": "merchant_shop_menu",
      "strategy": null,
      "triggers": [],
      "timers": []
    }
  }
}
```

#### Boss Enemy
```json
{
  "Actor": {
    "dragon_boss": {
      "name": "Ancient Dragon",
      "sprite": "dragon_sprite",
      "base": 128,
      "hitbox": "dragon_hitbox",
      "speed": 150.0,
      "perception": 600,
      "salience": 300,
      "skills": ["fire_breath", "tail_swipe", "wing_buffet", "roar"],
      "resources": ["health", "rage"],
      "measures": ["armor", "fire_resistance"],
      "public": ["health", "rage"],
      "private": [],
      "group": "boss",
      "menu": null,
      "strategy": "dragon_boss_ai",
      "triggers": ["enrage_at_50_percent", "phase_2_at_25_percent"],
      "timers": ["fire_breath_cooldown"],
      "on_touch": "dragon_knockback",
      "on_view": "dragon_aggro_roar",
      "on_map_entered": "boss_entrance_cutscene",
      "on_map_exited": "boss_defeated_reward"
    }
  }
}
```

### Actor Lifecycle

#### Spawning
Actors are spawned in two ways:

1. **Deployments** - Placed on maps at campaign load
2. **Actions** - Spawned dynamically via [spawn_actor_*](../actions/reference.md) actions

#### Runtime State
At runtime, actors have:
- **Position** - Current (x, y) on map
- **Resource values** - Current HP, mana, etc.
- **Target** - Current target actor
- **State** - Idle, moving, casting, etc.

#### Despawning
Actors are removed via:
- [despawn_self](../actions/reference.md#despawn_self) or [despawn_target](../actions/reference.md#despawn_target) actions
- Death (resource reaches 0 with associated trigger)
- Map transitions

### Resource Initialization

**Important:** All Resource entities defined in the campaign are automatically initialized on every actor, regardless of the `resources` field.

**Example:**
```json
{
  "Resource": {
    "health": { "default": 100, "min": 0, "max": 100 },
    "mana": { "default": 50, "min": 0, "max": 50 },
    "gold": { "default": 0, "min": 0, "max": 99999 }
  },
  "Actor": {
    "warrior": {
      "resources": ["health"]   // All 3 resources still initialized!
    }
  }
}
```

The `resources` field is used for:
- Defining which resources appear on the actor's UI
- Grouping related resources
- Documentation purposes

### Related Entities

- **Sprite** - Visual representation
- **Polygon** - Collision hitbox
- **Skill** - Available abilities
- **Resource** - Trackable stats
- **Measure** - Calculated values
- **Group** - Faction membership
- **Menu** - Interaction options
- **Strategy** - AI behaviors
- **Trigger** - Event handlers
- **Timer** - Scheduled actions
- **Action** - Event responses (on_touch, on_view, etc.)

---

**Next:** [Action System](action-system.md) | [Resources & Measures](resources.md) | [Back to Entity Overview](README.md)
