# Core Entities

## Main

The entry point for every campaign. Defines which actor the player controls and which map they start on.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `actor` | KeyRef (Actor) | Yes | The player's starting actor |
| `map` | KeyRef (Map) | Yes | The starting map |
| `notes` | String | No | Campaign description |

```json
{
  "Main": {
    "campaignMain": {
      "actor": "playerActor",
      "map": "startingMap"
    }
  }
}
```

Every campaign must have exactly one Main entity.

## Map

Defines a game level with terrain, NPCs, background, and audio.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | String | No | Display name |
| `tilemap` | KeyRef (TileMap) | Yes | Terrain grid |
| `spawn` | KeyRef (Vertex) | Yes | Player spawn position (x, y) |
| `deployments` | KeyRefArray (Deployment) | No | NPCs to spawn on this map |
| `background` | KeyRefArray (Parallax) | No | Background layers |
| `audio` | KeyRefArray (Sound) | No | Background music/ambience |
| `floor` | KeyRefArray (Floor) | No | Floor texture overlays |

```json
{
  "Map": {
    "forestMap": {
      "name": "Dark Forest",
      "tilemap": "forestTileMap",
      "spawn": "forestSpawn",
      "deployments": ["goblinDeploy", "merchantDeploy"],
      "background": ["forestBg"],
      "audio": ["forestAmbience"]
    }
  }
}
```

## Actor

Characters in the game world - both player-controlled and NPCs.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | String | No | Display name |
| `speed` | float | No | Movement speed (pixels/sec) |
| `bearing` | int | No | Facing direction (0-360, default 0 = north) |
| `sprite` | KeyRef (Sprite) | No | Visual appearance |
| `base` | int | Yes | Base circle radius in pixels |
| `hitbox` | KeyRef (Polygon) | No | Collision polygon |
| `perception` | int | No | Vision range in pixels |
| `salience` | int | No | How visible this actor is (0 = invisible) |
| `group` | KeyRef (Group) | No | Faction membership |
| `menu` | KeyRef (Menu) | No | Right-click context menu |
| `strategy` | KeyRef (Strategy) | No | AI behavior (NPCs only) |
| `skills` | KeyRefArray (Skill) | No | Action bar skills (max 9) |
| `resources` | KeyRefArray (Resource) | No | Tracked resources |
| `measures` | KeyRefArray (Measure) | No | Calculated values |
| `public` | KeyRefArray (Resource) | No | Resources shown on target focus |
| `private` | KeyRefArray (Resource) | No | Resources shown on own data plate |
| `triggers` | KeyRefArray (Trigger) | No | Resource change monitors |
| `timers` | KeyRefArray (Timer) | No | Periodic action executors |
| `on_touch` | KeyRef (Action) | No | Triggered when another actor touches this one |
| `on_view` | KeyRef (Action) | No | Triggered when this actor is first seen |
| `on_map_entered` | KeyRef (Action) | No | Triggered when entering a map |
| `on_map_exited` | KeyRef (Action) | No | Triggered when leaving a map |

```json
{
  "Actor": {
    "warrior": {
      "name": "Warrior",
      "speed": 1.0,
      "sprite": "warriorSprite",
      "polygon": "actorFootprint",
      "hitbox": "actorHitBox",
      "perception": 25,
      "salience": 1,
      "skills": ["slashSkill", "healSkill"],
      "resources": ["health", "mana"],
      "public": ["health"],
      "private": ["health", "mana"],
      "triggers": ["deathTrigger"],
      "timers": ["regenTimer"],
      "group": "playerGroup",
      "menu": "warriorMenu"
    }
  }
}
```

## Deployment

Defines where an NPC actor spawns on a map.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `location` | KeyRef (Vertex) | Yes | Spawn position (x, y) |
| `actor` | KeyRef (Actor) | Yes | Actor to deploy |

```json
{
  "Deployment": {
    "goblinSpawn": {
      "location": "goblinPos",
      "actor": "goblinActor"
    }
  },
  "Vertex": {
    "goblinPos": { "x": 400, "y": 300 }
  }
}
```

## Group

Defines a faction or team. Actors in the same group are allies.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | String | No | Group display name |
| `color` | String | No | Hex color for outline (e.g., "#FF0000") |

```json
{
  "Group": {
    "playerGroup": { "name": "Players", "color": "#00FF00" },
    "enemyGroup": { "name": "Enemies", "color": "#FF0000" },
    "neutralGroup": { "name": "Neutral", "color": "#FFFF00" }
  }
}
```
