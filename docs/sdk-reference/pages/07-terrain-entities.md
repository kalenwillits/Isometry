# Terrain Entities

## TileSet

Defines a collection of tiles from a texture atlas.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `columns` | int | Yes | Number of columns in the texture grid |
| `texture` | String | Yes | Path to tileset texture image |
| `tiles` | KeyRefArray (Tile) | Yes | Tile definitions |

```json
{
  "TileSet": {
    "forestTiles": {
      "columns": 8,
      "texture": "/assets/forest_tileset.png",
      "tiles": ["grass", "dirt", "water", "tree", "rock"]
    }
  }
}
```

## Tile

An individual tile type within a tileset.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `symbol` | String | Yes | Single character used in layer text grids |
| `index` | int | Yes | Position index in the tileset texture |
| `origin` | int | No | Y-sort origin offset |
| `navigation` | bool | No | Tile is walkable (true = pathfinding can cross) |
| `obstacle` | bool | No | Tile blocks movement (walls, rocks) |
| `ghost` | bool | No | Invisible but functional for pathfinding |

```json
{
  "Tile": {
    "grass": { "symbol": "G", "index": 0, "navigation": true },
    "water": { "symbol": "W", "index": 46 },
    "wall": { "symbol": "X", "index": 52, "obstacle": true }
  }
}
```

## TileMap

Combines a tileset with layers to define terrain.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `tileset` | KeyRef (TileSet) | Yes | Tile definitions to use |
| `layers` | KeyRefArray (Layer) | Yes | Map layers (ground, details, walls) |

```json
{
  "TileMap": {
    "forestTileMap": {
      "tileset": "forestTiles",
      "layers": ["groundLayer", "detailLayer", "wallLayer"]
    }
  }
}
```

## Layer

A single layer in a tilemap, referencing a text grid file.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `source` | String | Yes | Path to layer data file (text grid) |
| `ysort` | bool | No | Enable Y-sorting for depth rendering |

```json
{
  "Layer": {
    "groundLayer": { "source": "/mapName/layer0", "ysort": false },
    "detailLayer": { "source": "/mapName/layer1", "ysort": true },
    "wallLayer": { "source": "/mapName/layer2", "ysort": true }
  }
}
```

### Layer Data Format

Layer files are text grids where each character is a tile symbol:

```
XXXXXXXXXXXXXXXX
X    G   G     X
X  GGGGGGGG    X
X  G  WW  G    X
X  G  WW  G    X
X  GGGGGGGG    X
X    G   G     X
XXXXXXXXXXXXXXXX
```

- `G` = grass (walkable)
- `W` = water (not walkable)
- `X` = wall (obstacle)
- Space = empty (no tile)

The grid is rendered in isometric projection. Each character maps to one tile.

## Floor

A texture overlay placed at a specific position on a map.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `location` | KeyRef (Vertex) | Yes | Position (x, y) |
| `texture` | String | Yes | Path to texture image |

```json
{
  "Floor": {
    "dirtPatch": {
      "location": "dirtPos",
      "texture": "/assets/dirt_overlay.png"
    }
  }
}
```
