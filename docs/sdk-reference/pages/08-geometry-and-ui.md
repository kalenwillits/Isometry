# Geometry & UI Entities

## Polygon

Defines a shape from vertices, used for collision footprints and hitboxes.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `vertices` | KeyRefArray (Vertex) | Yes | Ordered boundary points |

```json
{
  "Polygon": {
    "actorFootprint": {
      "vertices": ["v1", "v2", "v3", "v4"]
    }
  },
  "Vertex": {
    "v1": { "x": 10, "y": 10 },
    "v2": { "x": 10, "y": -10 },
    "v3": { "x": -10, "y": -10 },
    "v4": { "x": -10, "y": 10 }
  }
}
```

Polygons are centered on the actor's position. A 20x20 square centered at origin uses vertices (10,10), (10,-10), (-10,-10), (-10,10).

## Vertex

A 2D coordinate point used throughout the system for positions, sizes, and shapes.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `x` | int | Yes | X coordinate |
| `y` | int | Yes | Y coordinate |

```json
{
  "Vertex": {
    "spawnPoint": { "x": 200, "y": 100 },
    "spriteSize": { "x": 64, "y": 64 }
  }
}
```

## Menu

A list of actions shown when right-clicking an actor or resource.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | String | No | Menu title |
| `actions` | KeyRefArray (Action) | Yes | Available actions |

```json
{
  "Menu": {
    "npcMenu": {
      "name": "Interact",
      "actions": ["talkAction", "tradeAction", "inspectAction"]
    }
  }
}
```

## Plate

A text display shown to the player (dialog, lore, status).

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | String | Yes | Title text |
| `text` | String | Yes | Body text (supports variable interpolation) |

Variable interpolation in plates:
- `{{@resourceName}}` - Current value of a resource
- `{{$resourceName}}` - Alternative resource syntax

```json
{
  "Plate": {
    "welcomePlate": {
      "title": "Welcome",
      "text": "Welcome to the village. Your health is {{@health}}."
    }
  }
}
```

## Waypoint

Named locations on a map for navigation and UI display.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | String | No | Display name |
| `location` | KeyRef (Vertex) | Yes | Position (x, y) |
| `icon` | String | No | Map icon path |
| `map` | KeyRef (Map) | No | Which map this waypoint is on |
| `menu` | KeyRef (Menu) | No | Interaction menu |
| `description` | String | No | Tooltip text |

```json
{
  "Waypoint": {
    "village": {
      "name": "Village Square",
      "location": "villagePos",
      "icon": "/assets/icons/village.png",
      "map": "forestMap",
      "description": "A bustling market town."
    }
  }
}
```
