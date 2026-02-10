# Isometry SDK Overview

The Isometry SDK allows content creators to build complete RPG campaigns using JSON configuration files. No programming is required.

## How Campaigns Work

A campaign is a collection of JSON files and assets (images, audio) packaged into a ZIP archive. Each JSON file defines one or more **entities** - the building blocks of your game world.

## Entity System

Isometry uses 30 entity types organized into categories:

| Category | Entities |
|----------|----------|
| **Core** | Main, Map, Actor |
| **Actions** | Action, Condition, Parameter |
| **Resources** | Resource, Measure |
| **Skills** | Skill |
| **AI** | Strategy, Behavior |
| **Events** | Trigger, Timer |
| **Visual** | Sprite, Animation, AnimationSet |
| **Terrain** | TileSet, Tile, TileMap, Layer, Floor |
| **Geometry** | Polygon, Vertex |
| **Audio** | Sound, Parallax |
| **UI** | Menu, Plate, Waypoint |
| **Social** | Group, Deployment |

## JSON Format

All entities follow this pattern:

```json
{
  "EntityType": {
    "entityKey": {
      "field1": "value1",
      "field2": "value2"
    }
  }
}
```

Multiple entity types can share a single JSON file:

```json
{
  "Actor": {
    "myActor": { ... }
  },
  "Skill": {
    "mySkill": { ... }
  }
}
```

## Reference System (KeyRef)

Entities reference each other by key name. For example, an Actor's `sprite` field contains the key of a Sprite entity:

```json
{
  "Actor": {
    "hero": {
      "sprite": "heroSprite"
    }
  },
  "Sprite": {
    "heroSprite": {
      "texture": "/assets/hero.png"
    }
  }
}
```

References are resolved at load time. If a referenced entity doesn't exist, validation will report an error.

## Campaign Directory Structure

```
my-campaign/
├── Main.json              # Required: campaign entry point
├── actors.json            # Actor definitions
├── maps.json              # Map definitions
├── skills.json            # Skills and actions
├── resources.json         # Health, mana, etc.
├── tileset.json           # Terrain tiles
├── polygons/              # Collision data
│   └── polygons.json
├── mapName/               # Map layer data
│   ├── layer0             # Ground layer (text grid)
│   ├── layer1             # Detail layer
│   └── layer2             # Wall/obstacle layer
└── assets/                # Images, audio, fonts
    ├── sprite.png
    ├── tileset.png
    ├── icons/
    └── Audio/
```

## Building a Campaign

1. Create your JSON entity files
2. Create map layers as text grids using tile symbols
3. Add assets (images, audio)
4. Package everything into a ZIP file
5. Place the ZIP in the campaigns directory

```bash
cd my-campaign/
zip -r my-campaign.zip . -x "*.DS_Store"
cp my-campaign.zip ~/path/to/campaigns/
```
