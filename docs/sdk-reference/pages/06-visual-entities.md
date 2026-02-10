# Visual Entities

## Sprite

Defines an actor's visual appearance.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `animation_set` | KeyRef (AnimationSet) | No | Available animations |
| `texture` | String | Yes | Path to sprite sheet image |
| `size` | KeyRef (Vertex) | Yes | Sprite dimensions (width, height) |
| `margin` | KeyRef (Vertex) | No | Render offset (x, y) |

```json
{
  "Sprite": {
    "heroSprite": {
      "animation_set": "heroAnims",
      "texture": "/assets/hero_sheet.png",
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

## AnimationSet

A named collection of animations available to a sprite.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | String | No | Set name |
| `animations` | KeyRefArray (Animation) | Yes | Available animations |

```json
{
  "AnimationSet": {
    "heroAnims": {
      "name": "Hero Animations",
      "animations": ["idle", "walk", "attack"]
    }
  }
}
```

## Animation

Defines frame sequences for 8-directional sprite animation.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `N` | Array | No | North-facing frame indices |
| `NE` | Array | No | Northeast frame indices |
| `E` | Array | No | East frame indices |
| `SE` | Array | No | Southeast frame indices |
| `S` | Array | No | South frame indices |
| `SW` | Array | No | Southwest frame indices |
| `W` | Array | No | West frame indices |
| `NW` | Array | No | Northwest frame indices |
| `sound` | KeyRef (Sound) | No | Sound to play with animation |
| `loop` | bool | No | Whether animation loops |

Frame indices reference positions in the sprite sheet grid.

```json
{
  "Animation": {
    "walk": {
      "N": [0, 8, 16, 24],
      "NE": [1, 9, 17, 25],
      "E": [2, 10, 18, 26],
      "SE": [3, 11, 19, 27],
      "S": [4, 12, 20, 28],
      "SW": [5, 13, 21, 29],
      "W": [6, 14, 22, 30],
      "NW": [7, 15, 23, 31],
      "loop": true
    }
  }
}
```

## Parallax

Background layers that scroll at different speeds for depth effect.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `texture` | String | Yes | Path to background image |
| `effect` | float | Yes | Scroll speed multiplier (lower = slower) |

```json
{
  "Parallax": {
    "farBg": { "texture": "/assets/sky.png", "effect": 20 },
    "nearBg": { "texture": "/assets/clouds.png", "effect": 60 }
  }
}
```

## Sound

Audio files for music, ambience, and effects.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `source` | String | Yes | Path to audio file |
| `scale` | String | No | Volume scale (dice expression) |
| `loop` | bool | No | Whether audio loops |

```json
{
  "Sound": {
    "bgMusic": {
      "source": "/assets/Audio/theme.mp3",
      "scale": "1d200",
      "loop": true
    },
    "hitSound": {
      "source": "/assets/Audio/hit.mp3",
      "scale": "50+(1d100)"
    }
  }
}
```
