# Resources & Measures

## Resource

Tracked numeric values on actors (health, mana, gold, etc.).

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | String | No | Display name |
| `default` | int | No | Starting value |
| `min` | int | No | Minimum allowed value |
| `max` | int | No | Maximum allowed value |
| `icon` | String | No | Icon path for UI display |
| `description` | String | No | Tooltip text |
| `reveal` | int | No | Visibility threshold (0 = always visible) |
| `menu` | KeyRef (Menu) | No | Right-click menu for this resource |

```json
{
  "Resource": {
    "health": {
      "name": "Health",
      "default": 20,
      "min": 0,
      "max": 20,
      "icon": "/assets/icons/health.png",
      "description": "Hit points. Reach 0 and you're done."
    },
    "mana": {
      "name": "Mana",
      "default": 10,
      "min": 0,
      "max": 10,
      "icon": "/assets/icons/mana.png",
      "description": "Magical energy for casting."
    }
  }
}
```

### Resource Visibility

- **public**: Resources listed in an actor's `public` array appear on the focus plate when others target them
- **private**: Resources listed in `private` appear on the actor's own data plate
- **reveal**: If set to a non-zero value, the resource only appears after hitting that threshold

## Measure

Calculated values using dice expressions, evaluated on demand.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `expression` | String | Yes | Dice expression to evaluate |
| `icon` | String | No | Icon path |
| `public` | bool | No | Show on target focus plate |
| `private` | bool | No | Show on own data plate |
| `reveal` | int | No | Visibility threshold |
| `menu` | KeyRef (Menu) | No | Right-click menu |

```json
{
  "Measure": {
    "luckCheck": {
      "expression": "1d20",
      "icon": "/assets/icons/luck.png",
      "public": false,
      "private": true
    }
  }
}
```

## Trigger

Monitors a resource and executes an action when its value changes.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `resource` | KeyRef (Resource) | Yes | Resource to monitor |
| `action` | KeyRef (Action) | Yes | Action to execute on change |

```json
{
  "Trigger": {
    "deathTrigger": {
      "resource": "health",
      "action": "deathAction"
    }
  }
}
```

A common pattern is combining a trigger with a conditional action to check if health reached zero.

## Timer

Executes an action at regular intervals.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `total` | String | No | Total duration (dice expression, empty = infinite) |
| `interval` | String | Yes | Time between executions (dice expression) |
| `action` | KeyRef (Action) | Yes | Action to execute each interval |

```json
{
  "Timer": {
    "healthRegen": {
      "total": "",
      "interval": "1d12",
      "action": "regenAction"
    }
  }
}
```

A timer with empty `total` runs indefinitely. The `interval` uses dice expressions, adding randomness to execution timing.
