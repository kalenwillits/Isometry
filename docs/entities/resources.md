# Resources and Measures

Documentation for Resource and Measure entities that track actor stats and calculated values.

## Table of Contents

- [Resource Entity](#resource-entity)
- [Measure Entity](#measure-entity)

## Resource Entity

### Purpose

The **Resource** entity defines trackable numeric values for actors (health, mana, gold, stamina, etc.).

### Tags

`Group.RESOURCE_ENTITY`

### File

`/home/kalen/Dev/atlas/app/entities/Resource.gd`

### Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `name` | String | Yes | - | Display name |
| `default` | Int | Yes | - | Starting value |
| `min` | Int | Yes | - | Minimum value |
| `max` | Int | Yes | - | Maximum value |
| `icon` | String | No | `""` | Icon path for UI |
| `reveal` | Int | No | `0` | Visibility threshold |
| `menu` | KeyRef | No | `null` | Interaction menu |
| `description` | String | No | `""` | Description text |

### Field Details

#### name
- **Type**: String
- **Required**: Yes
- **Description**: Human-readable name displayed in UI
- **Example**: `"Health"`, `"Mana"`, `"Gold"`, `"Experience"`

#### default
- **Type**: Int
- **Required**: Yes
- **Description**: Starting value when actor is created
- **Example**: `100` (full health), `50` (half mana), `0` (no gold)

#### min
- **Type**: Int
- **Required**: Yes
- **Description**: Minimum allowed value (cannot go below)
- **Example**: `0` (most resources), `-100` (if negative allowed)

#### max
- **Type**: Int
- **Required**: Yes
- **Description**: Maximum allowed value (cannot exceed)
- **Example**: `100` (health cap), `999999` (gold cap)

#### icon
- **Type**: String (file path)
- **Required**: No
- **Default**: `""`
- **Description**: Path to icon image for UI display
- **Example**: `"assets/icons/health.png"`

#### reveal
- **Type**: Int
- **Required**: No
- **Default**: `0`
- **Description**: Visibility threshold (0 = always visible)
- **Use**: Hide resources until certain conditions met

#### menu
- **Type**: KeyRef to Menu entity
- **Required**: No
- **Default**: `null`
- **Description**: Right-click menu for this resource
- **Use**: Trading, crafting, custom interactions

#### description
- **Type**: String
- **Required**: No
- **Default**: `""`
- **Description**: Tooltip or help text

### JSON Example - Health

```json
{
  "Resource": {
    "health": {
      "name": "Health",
      "default": 100,
      "min": 0,
      "max": 100,
      "icon": "assets/icons/heart.png",
      "reveal": 0,
      "description": "Life force. When it reaches 0, you die."
    }
  }
}
```

### JSON Example - Mana

```json
{
  "Resource": {
    "mana": {
      "name": "Mana",
      "default": 50,
      "min": 0,
      "max": 50,
      "icon": "assets/icons/mana.png",
      "reveal": 0,
      "description": "Magical energy used to cast spells."
    }
  }
}
```

### JSON Example - Gold

```json
{
  "Resource": {
    "gold": {
      "name": "Gold",
      "default": 0,
      "min": 0,
      "max": 999999,
      "icon": "assets/icons/coin.png",
      "reveal": 0,
      "menu": "gold_menu",
      "description": "Currency used for trading and purchasing items."
    }
  }
}
```

### Resource Operations

Resources are modified via actions:

**Add to resource:**
```json
{
  "Action": {
    "heal_10": {
      "do": "plus_resource_self",
      "parameters": [
        { "Parameter": { "res": { "name": "resource", "value": "health" } } },
        { "Parameter": { "amt": { "name": "expression", "value": "10" } } }
      ]
    }
  }
}
```

**Subtract from resource:**
```json
{
  "Action": {
    "damage_15": {
      "do": "minus_resource_target",
      "parameters": [
        { "Parameter": { "res": { "name": "resource", "value": "health" } } },
        { "Parameter": { "dmg": { "name": "expression", "value": "15" } } }
      ]
    }
  }
}
```

**Set resource value:**
```json
{
  "Action": {
    "reset_health": {
      "do": "set_resource_self",
      "parameters": [
        { "Parameter": { "res": { "name": "resource", "value": "health" } } },
        { "Parameter": { "val": { "name": "expression", "value": "100" } } }
      ]
    }
  }
}
```

**Transfer between actors:**
```json
{
  "Action": {
    "steal_gold": {
      "do": "transfer_resource",
      "parameters": [
        { "Parameter": { "res": { "name": "resource", "value": "gold" } } },
        { "Parameter": { "amt": { "name": "expression", "value": "2d10" } } }
      ]
    }
  }
}
```

### Resource Initialization

**Important:** All Resource entities are automatically initialized on every actor, regardless of whether the actor references them.

```json
{
  "Resource": {
    "health": { "default": 100, "min": 0, "max": 100 },
    "mana": { "default": 50, "min": 0, "max": 50 },
    "gold": { "default": 0, "min": 0, "max": 99999 }
  },
  "Actor": {
    "warrior": {
      "resources": ["health"]   
    }
  }
}
```

Even though the warrior only lists `health`, all three resources (health, mana, gold) are initialized with their default values.

### Visibility

Resources can be shown to different audiences:

**Public** - Visible when others target this actor:
```json
{
  "Actor": {
    "warrior": {
      "public": ["health"]   // Others see warrior's health bar
    }
  }
}
```

**Private** - Visible only to the actor's owner:
```json
{
  "Actor": {
    "warrior": {
      "private": ["mana", "gold"]   // Only you see your mana and gold
    }
  }
}
```

**Hidden** - Not displayed (but still tracked):
```json
{
  "Resource": {
    "hidden_counter": {
      "name": "Hidden Counter",
      "default": 0,
      "min": 0,
      "max": 999,
      "reveal": 999   // Very high reveal threshold = never shown
    }
  }
}
```

### Common Resource Types

```json
{
  "Resource": {
    "health": {
      "name": "Health",
      "default": 100,
      "min": 0,
      "max": 100,
      "icon": "assets/icons/health.png"
    },
    "mana": {
      "name": "Mana",
      "default": 50,
      "min": 0,
      "max": 50,
      "icon": "assets/icons/mana.png"
    },
    "stamina": {
      "name": "Stamina",
      "default": 100,
      "min": 0,
      "max": 100,
      "icon": "assets/icons/stamina.png"
    },
    "experience": {
      "name": "Experience",
      "default": 0,
      "min": 0,
      "max": 999999,
      "icon": "assets/icons/exp.png"
    },
    "gold": {
      "name": "Gold",
      "default": 0,
      "min": 0,
      "max": 999999,
      "icon": "assets/icons/gold.png"
    },
    "rage": {
      "name": "Rage",
      "default": 0,
      "min": 0,
      "max": 100,
      "icon": "assets/icons/rage.png"
    }
  }
}
```

### Related Entities

- **Actor** - Resources are tracked per actor
- **Action** - Actions modify resources
- **Trigger** - Monitors resource changes
- **Measure** - Calculated resource values

---

## Measure Entity

### Purpose

The **Measure** entity defines calculated values based on dice expressions (armor class, damage output, spell power, etc.).

**Key difference from Resource:** Measures are computed on-demand, not stored.

### Tags

`Group.MEASURE_ENTITY`

### File

`/home/kalen/Dev/atlas/app/entities/Measure.gd`

### Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `expression` | String | Yes | - | Dice expression to calculate value |
| `icon` | String | No | `""` | Icon path for UI |
| `public` | Bool | No | `false` | Show on target focus plate |
| `private` | Bool | No | `false` | Show on own data plate |
| `reveal` | Int | No | `0` | Visibility threshold |
| `menu` | KeyRef | No | `null` | Interaction menu |

### Field Details

#### expression
- **Type**: String (dice expression)
- **Required**: Yes
- **Description**: Formula to calculate the measure value
- **Format**: Dice notation (see [Dice Notation](../appendix/dice-notation.md))
- **Example**: `"2d6+3"`, `"1d20"`, `"10"`

#### icon
- **Type**: String (file path)
- **Required**: No
- **Default**: `""`
- **Description**: Icon for UI display

#### public
- **Type**: Bool
- **Required**: No
- **Default**: `false`
- **Description**: If true, shown when others target this actor

#### private
- **Type**: Bool
- **Required**: No
- **Default**: `false`
- **Description**: If true, shown on own UI

#### reveal
- **Type**: Int
- **Required**: No
- **Default**: `0`
- **Description**: Visibility threshold

#### menu
- **Type**: KeyRef to Menu entity
- **Required**: No
- **Default**: `null`
- **Description**: Right-click menu

### JSON Example - Armor Class

```json
{
  "Measure": {
    "armor_class": {
      "expression": "10+2d4",
      "icon": "assets/icons/armor.png",
      "public": true,
      "private": true,
      "reveal": 0
    }
  }
}
```

### JSON Example - Spell Power

```json
{
  "Measure": {
    "spell_power": {
      "expression": "5d6+15",
      "icon": "assets/icons/magic.png",
      "public": false,
      "private": true,
      "reveal": 0
    }
  }
}
```

### Measure vs Resource

| Feature | Resource | Measure |
|---------|----------|---------|
| **Storage** | Stored value | Calculated on-demand |
| **Modification** | Changed via actions | Recalculated each time |
| **Persistence** | Saved with actor | Not saved (formula saved) |
| **Use case** | Health, mana, gold | Armor, DPS, crit chance |
| **Dice** | No (static values) | Yes (evaluated each time) |

### When to Use Measures

**Use Measure when:**
- Value should vary each time (randomness)
- Value is derived from other stats
- Value doesn't need to persist

**Use Resource when:**
- Value needs to be stored
- Value changes frequently
- Value must be saved

### Common Measures

```json
{
  "Measure": {
    "armor_class": {
      "expression": "10+1d6",
      "icon": "assets/icons/armor.png",
      "public": true
    },
    "dodge_chance": {
      "expression": "1d100",
      "icon": "assets/icons/dodge.png",
      "public": false,
      "private": true
    },
    "critical_hit_chance": {
      "expression": "5+1d20",
      "icon": "assets/icons/crit.png",
      "private": true
    },
    "spell_resistance": {
      "expression": "3d6",
      "icon": "assets/icons/resist.png",
      "public": true
    }
  }
}
```

### Usage in Actor

```json
{
  "Actor": {
    "armored_knight": {
      "name": "Knight",
      "resources": ["health", "stamina"],
      "measures": ["armor_class", "block_chance"],
      "public": ["health", "armor_class"],
      "private": ["stamina", "block_chance"]
    }
  },
  "Measure": {
    "armor_class": {
      "expression": "15+2d6",
      "public": true
    },
    "block_chance": {
      "expression": "25+1d20",
      "private": true
    }
  }
}
```

When displayed:
- Other players see: Health bar, Armor Class value (varies each check)
- Only you see: Stamina bar, Block Chance value (random each time)

### Related Entities

- **Actor** - Measures are associated with actors
- **Resource** - Similar to measures but stored

---

**Next:** [Skills](skills.md) | [AI System](ai-system.md) | [Back to Entity Overview](README.md)
