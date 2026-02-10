# Complete Campaign Example

This chapter walks through creating a minimal but complete campaign that demonstrates all core entity types.

## Step 1: Main Entry Point

Every campaign starts with a `Main.json`:

```json
{
  "Main": {
    "campaignMain": {
      "actor": "hero",
      "map": "townMap"
    }
  }
}
```

## Step 2: Define Terrain

Create the tileset, tiles, tilemap, and layers:

```json
{
  "TileSet": {
    "baseTiles": {
      "columns": 8,
      "texture": "/assets/tileset.png",
      "tiles": ["grass", "water", "wall"]
    }
  },
  "Tile": {
    "grass": { "symbol": "G", "index": 0, "navigation": true },
    "water": { "symbol": "W", "index": 46 },
    "wall": { "symbol": "X", "index": 52, "obstacle": true }
  },
  "TileMap": {
    "townTileMap": {
      "tileset": "baseTiles",
      "layers": ["ground", "walls"]
    }
  },
  "Layer": {
    "ground": { "source": "/townMap/layer0", "ysort": false },
    "walls": { "source": "/townMap/layer1", "ysort": true }
  }
}
```

Create `townMap/layer0` (ground):
```
GGGGGGGGGGGGGGGG
GGGGGGGGGGGGGGGG
GGGGGGGGGGGGGGGG
GGGGGGGGGGGGGGGG
```

Create `townMap/layer1` (walls):
```
XXXXXXXXXXXXXXXX
X              X
X              X
XXXXXXXXXXXXXXXX
```

## Step 3: Define the Map

```json
{
  "Map": {
    "townMap": {
      "name": "Town",
      "tilemap": "townTileMap",
      "spawn": "playerSpawn",
      "deployments": ["npcDeploy"]
    }
  },
  "Vertex": {
    "playerSpawn": { "x": 200, "y": 100 }
  }
}
```

## Step 4: Create the Player Actor

```json
{
  "Actor": {
    "hero": {
      "name": "Hero",
      "speed": 1.0,
      "sprite": "heroSprite",
      "polygon": "footprint",
      "hitbox": "hitbox",
      "perception": 25,
      "salience": 1,
      "skills": ["attackSkill"],
      "resources": ["health"],
      "public": ["health"],
      "private": ["health"],
      "triggers": ["deathTrigger"],
      "group": "playerGroup",
      "menu": "heroMenu"
    }
  },
  "Sprite": {
    "heroSprite": {
      "animation_set": "heroAnims",
      "texture": "/assets/hero.png",
      "size": "spriteSize",
      "margin": "spriteMargin"
    }
  },
  "Vertex": {
    "spriteSize": { "x": 64, "y": 64 },
    "spriteMargin": { "x": 16, "y": 16 }
  }
}
```

## Step 5: Add Resources and Skills

```json
{
  "Resource": {
    "health": {
      "name": "Health",
      "default": 20,
      "min": 0,
      "max": 20,
      "icon": "/assets/icons/health.png"
    }
  },
  "Skill": {
    "attackSkill": {
      "name": "Attack",
      "start": "attackAction",
      "end": "attackAction",
      "icon": "/assets/icons/sword.png"
    }
  },
  "Action": {
    "attackAction": {
      "name": "Attack",
      "time": 1.0,
      "do": "minus_resource_target",
      "parameters": ["healthParam", "damageParam"]
    }
  },
  "Parameter": {
    "healthParam": { "name": "resource", "value": "health" },
    "damageParam": { "name": "expression", "value": "1d6" }
  }
}
```

## Step 6: Add NPC with AI

```json
{
  "Actor": {
    "guard": {
      "name": "Guard",
      "speed": 0.5,
      "sprite": "heroSprite",
      "polygon": "footprint",
      "hitbox": "hitbox",
      "perception": 15,
      "salience": 1,
      "resources": ["health"],
      "group": "enemyGroup",
      "strategy": "patrolStrategy"
    }
  },
  "Deployment": {
    "npcDeploy": {
      "location": "guardPos",
      "actor": "guard"
    }
  },
  "Vertex": {
    "guardPos": { "x": 400, "y": 200 }
  }
}
```

## Step 7: Package and Test

```bash
cd my-campaign/
zip -r my-campaign.zip .
cp my-campaign.zip ~/path/to/campaigns/
./isometry_linux.x86_64 --campaign=my-campaign --network=host \
  --port=5000 --username=test --password=test
```

## Validation

Isometry validates all entities on load. Common validation errors:

- **Missing required field** - A field like `do` on an Action is empty
- **Invalid KeyRef** - A referenced entity key doesn't exist
- **Type mismatch** - A field expects a number but received a string
- **Missing Main** - No Main entity found in the campaign

Run with `--log-level=trace` to see detailed validation output.
