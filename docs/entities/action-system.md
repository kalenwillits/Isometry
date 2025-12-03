# Action System Entities

Documentation for Action, Condition, and Parameter entities that form the action execution system.

## Table of Contents

- [Action Entity](#action-entity)
- [Condition Entity](#condition-entity)
- [Parameter Entity](#parameter-entity)

## Action Entity

### Purpose

The **Action** entity defines executable behaviors that affect actors, resources, and game state. Actions form the core of Isometry's gameplay logic.

### Tags

`Group.ACTION_ENTITY`

### File

`/home/kalen/Dev/atlas/app/entities/Action.gd`

### Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `name` | String | Yes | - | Human-readable action name |
| `do` | String | Yes | - | Function name to execute |
| `parameters` | KeyRefArray | No | `[]` | Parameters passed to function |
| `if` | KeyRef | No | `null` | Condition to check before executing |
| `else` | KeyRef | No | `null` | Action to run if condition fails |
| `then` | KeyRef | No | `null` | Action to run after successful execution |
| `time` | Float | No | `0.0` | Execution duration (seconds) |
| `animation` | KeyRef | No | `null` | Animation to play during execution |

### Field Details

#### name
- **Type**: String
- **Required**: Yes
- **Description**: Display name for the action (used in UI, logs, debugging)
- **Example**: `"Fireball"`, `"Heal Ally"`, `"Open Door"`

#### do
- **Type**: String (function name)
- **Required**: Yes
- **Description**: Name of the function to execute. Must match one of the 69 available action functions.
- **See**: [Action Reference](../actions/reference.md) for all valid functions
- **Example**: `"plus_resource_self"`, `"move_to_target"`, `"spawn_actor_at_self"`

#### parameters
- **Type**: KeyRefArray to Parameter entities
- **Required**: No (depends on function)
- **Default**: `[]`
- **Description**: Parameters passed to the action function
- **See**: [Parameter Entity](#parameter-entity)

#### if
- **Type**: KeyRef to Condition entity
- **Required**: No
- **Default**: `null`
- **Description**: Condition evaluated before executing the action
- **Behavior**: If condition is false, action doesn't execute (unless `else` is defined)
- **See**: [Condition Entity](#condition-entity)

#### else
- **Type**: KeyRef to Action entity
- **Required**: No
- **Default**: `null`
- **Description**: Action to execute if the `if` condition fails
- **Use**: Fallback behaviors, alternative actions

#### then
- **Type**: KeyRef to Action entity
- **Required**: No
- **Default**: `null`
- **Description**: Action to execute after this action completes successfully
- **Use**: Action chaining, sequences

#### time
- **Type**: Float (seconds)
- **Required**: No
- **Default**: `0.0`
- **Description**: How long the action takes to execute (for animations, channeling)
- **Use**: Cast times, animation durations

#### animation
- **Type**: KeyRef to Animation entity
- **Required**: No
- **Default**: `null`
- **Description**: Animation to play while executing the action
- **See**: [Animation Entity](visual-entities.md#animation-entity)

### JSON Example - Simple Action

```json
{
  "Action": {
    "heal_self": {
      "name": "Heal Self",
      "do": "plus_resource_self",
      "parameters": [
        { "Parameter": { "res": { "name": "resource", "value": "health" } } },
        { "Parameter": { "amt": { "name": "expression", "value": "2d6+5" } } }
      ],
      "time": 1.5,
      "animation": "healing_anim"
    }
  }
}
```

### Execution Flow

```
┌─────────────┐
│ Action      │
│ Invoked     │
└──────┬──────┘
       │
       ▼
┌─────────────┐     No      ┌─────────────┐
│ Has 'if'?   │────────────►│ Execute     │
└──────┬──────┘             │ 'do'        │
       │ Yes                └──────┬──────┘
       ▼                           │
┌─────────────┐                    ▼
│ Evaluate    │             ┌─────────────┐
│ Condition   │             │ Has 'then'? │
└──────┬──────┘             └──────┬──────┘
       │                           │ Yes
    True│  False                   ▼
       ▼      ▼              ┌─────────────┐
  ┌────────┐ ┌─────────┐    │ Execute     │
  │Execute │ │Has      │    │ 'then'      │
  │'do'    │ │'else'?  │    │ Action      │
  └────────┘ └────┬────┘    └─────────────┘
                  │ Yes
                  ▼
            ┌─────────────┐
            │ Execute     │
            │ 'else'      │
            │ Action      │
            └─────────────┘
```

### Example - Conditional Action

```json
{
  "Action": {
    "heal_if_low": {
      "name": "Heal If Low Health",
      "do": "plus_resource_self",
      "if": "health_below_50",
      "else": "attack_instead",
      "parameters": [
        { "Parameter": { "res": { "name": "resource", "value": "health" } } },
        { "Parameter": { "amt": { "name": "expression", "value": "30" } } }
      ]
    }
  },
  "Condition": {
    "health_below_50": {
      "left": "self.health",
      "operator": "<",
      "right": "50"
    }
  },
  "Action": {
    "attack_instead": {
      "name": "Attack",
      "do": "minus_resource_target",
      "parameters": [
        { "Parameter": { "res": { "name": "resource", "value": "health" } } },
        { "Parameter": { "dmg": { "name": "expression", "value": "1d8+3" } } }
      ]
    }
  }
}
```

### Example - Action Chain

```json
{
  "Action": {
    "teleport_strike": {
      "name": "Teleport Strike",
      "do": "teleport_self_to_target",
      "then": "sword_slash",
      "time": 0.5,
      "animation": "teleport_anim"
    },
    "sword_slash": {
      "name": "Sword Slash",
      "do": "minus_resource_target",
      "then": "teleport_back",
      "parameters": [
        { "Parameter": { "res": { "name": "resource", "value": "health" } } },
        { "Parameter": { "dmg": { "name": "expression", "value": "3d6+8" } } }
      ],
      "time": 0.3,
      "animation": "slash_anim"
    },
    "teleport_back": {
      "name": "Teleport Back",
      "do": "teleport_to_radial",
      "parameters": [
        { "Parameter": { "rad": { "name": "radial", "value": "180" } } },
        { "Parameter": { "dist": { "name": "distance", "value": "100" } } }
      ],
      "time": 0.5
    }
  }
}
```

This creates a sequence: Teleport to target → Slash → Teleport away

### Common Patterns

#### Damage Action
```json
{
  "Action": {
    "fireball_damage": {
      "name": "Fireball Damage",
      "do": "minus_resource_target",
      "parameters": [
        { "Parameter": { "res": { "name": "resource", "value": "health" } } },
        { "Parameter": { "dmg": { "name": "expression", "value": "4d6+10" } } }
      ]
    }
  }
}
```

#### Heal Action
```json
{
  "Action": {
    "healing_touch": {
      "name": "Healing Touch",
      "do": "plus_resource_target",
      "parameters": [
        { "Parameter": { "res": { "name": "resource", "value": "health" } } },
        { "Parameter": { "heal": { "name": "expression", "value": "3d8+5" } } }
      ],
      "time": 2.0,
      "animation": "healing_anim"
    }
  }
}
```

#### Buff Action
```json
{
  "Action": {
    "speed_boost": {
      "name": "Speed Boost",
      "do": "temp_speed_self",
      "parameters": [
        { "Parameter": { "spd": { "name": "speed", "value": "400" } } },
        { "Parameter": { "dur": { "name": "duration", "value": "10" } } }
      ]
    }
  }
}
```

### Related Entities

- **Condition** - Conditional logic
- **Parameter** - Action parameters
- **Skill** - Skills reference actions
- **Trigger** - Triggers execute actions
- **Timer** - Timers execute actions
- **Animation** - Visual feedback

---

## Condition Entity

### Purpose

The **Condition** entity defines boolean comparisons used for conditional action execution.

### Tags

`Group.CONDITION_ENTITY`

### File

`/home/kalen/Dev/atlas/app/entities/Condition.gd`

### Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `left` | String | Yes | - | Left operand |
| `operator` | String | Yes | - | Comparison operator |
| `right` | String | Yes | - | Right operand |

### Field Details

#### left
- **Type**: String (expression or reference)
- **Required**: Yes
- **Description**: Left side of the comparison
- **Formats**:
  - Literal value: `"50"`
  - Resource reference: `"self.health"`, `"target.mana"`
  - Dice expression: `"2d6+3"` (planned feature)

#### operator
- **Type**: String
- **Required**: Yes
- **Description**: Comparison operator
- **Valid operators**:
  - `"=="` or `"="` - Equal
  - `"!="` or `"<>"` - Not equal
  - `"<"` - Less than
  - `">"` - Greater than
  - `"<="` - Less than or equal
  - `">="` - Greater than or equal

#### right
- **Type**: String (expression or reference)
- **Required**: Yes
- **Description**: Right side of the comparison
- **Formats**: Same as `left`

### JSON Examples

#### Compare Resource to Value
```json
{
  "Condition": {
    "health_below_50": {
      "left": "self.health",
      "operator": "<",
      "right": "50"
    }
  }
}
```

#### Compare Two Resources
```json
{
  "Condition": {
    "health_exceeds_mana": {
      "left": "self.health",
      "operator": ">",
      "right": "self.mana"
    }
  }
}
```

#### Exact Match
```json
{
  "Condition": {
    "health_full": {
      "left": "self.health",
      "operator": "==",
      "right": "100"
    }
  }
}
```

#### Target Comparison
```json
{
  "Condition": {
    "target_low_health": {
      "left": "target.health",
      "operator": "<=",
      "right": "25"
    }
  }
}
```

### Usage in Actions

```json
{
  "Action": {
    "conditional_heal": {
      "name": "Heal If Injured",
      "do": "plus_resource_self",
      "if": "health_below_75",
      "else": "do_nothing",
      "parameters": [
        { "Parameter": { "res": { "name": "resource", "value": "health" } } },
        { "Parameter": { "amt": { "name": "expression", "value": "50" } } }
      ]
    }
  },
  "Condition": {
    "health_below_75": {
      "left": "self.health",
      "operator": "<",
      "right": "75"
    }
  }
}
```

### Common Patterns

#### Health Threshold
```json
{
  "Condition": {
    "critical_health": { "left": "self.health", "operator": "<", "right": "20" },
    "low_health": { "left": "self.health", "operator": "<", "right": "50" },
    "healthy": { "left": "self.health", "operator": ">", "right": "75" }
  }
}
```

#### Resource Check
```json
{
  "Condition": {
    "has_mana": { "left": "self.mana", "operator": ">=", "right": "30" },
    "can_afford": { "left": "self.gold", "operator": ">=", "right": "100" }
  }
}
```

### Related Entities

- **Action** - Uses conditions for if/else logic

---

## Parameter Entity

### Purpose

The **Parameter** entity defines name-value pairs passed to action functions.

### Tags

`Group.PARAMETER_ENTITY`

### File

`/home/kalen/Dev/atlas/app/entities/Parameter.gd`

### Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `name` | String | Yes | - | Parameter name (must match function signature) |
| `value` | String | Yes | - | Parameter value |

### Field Details

#### name
- **Type**: String
- **Required**: Yes
- **Description**: Parameter name matching the action function's expected parameter
- **Example**: `"resource"`, `"expression"`, `"distance"`, `"radial"`

#### value
- **Type**: String
- **Required**: Yes
- **Description**: Parameter value (parsed based on parameter type)
- **Formats**:
  - Entity key: `"health"`, `"mana"`
  - Number: `"100"`, `"3.14"`
  - Dice expression: `"2d6+3"`
  - Angle: `"180"` (degrees)

### Parameter Names by Action Type

**Resource actions** (plus/minus/set resource):
- `resource` - Resource entity key
- `expression` - Dice expression for amount

**Movement actions**:
- `radial` - Angle in degrees (0-360)
- `distance` - Distance in pixels

**Spawning actions**:
- `actor` - Actor entity key

**Map transition actions**:
- `map` - Map entity key
- `location` - Vertex entity key

**Speed actions**:
- `speed` - Speed value (pixels/second)
- `duration` - Duration in seconds (for temp speed)

**AoE actions**:
- `action` - Action entity key to apply
- `radius` - Effect radius in pixels
- `radial` - Direction (degrees)
- `distance` - Distance from origin

See [Action Reference](../actions/reference.md) for parameter requirements of each action.

### JSON Examples

#### Resource Parameters
```json
{
  "Parameter": {
    "health_param": {
      "name": "resource",
      "value": "health"
    },
    "damage_amount": {
      "name": "expression",
      "value": "2d6+5"
    }
  }
}
```

#### Movement Parameters
```json
{
  "Parameter": {
    "angle_param": {
      "name": "radial",
      "value": "90"
    },
    "distance_param": {
      "name": "distance",
      "value": "200"
    }
  }
}
```

#### Complete Action with Parameters
```json
{
  "Action": {
    "fireball": {
      "name": "Fireball",
      "do": "area_of_effect_at_target",
      "parameters": [
        { "Parameter": { "action_param": { "name": "action", "value": "fire_damage" } } },
        { "Parameter": { "radius_param": { "name": "radius", "value": "100" } } }
      ]
    },
    "fire_damage": {
      "name": "Fire Damage",
      "do": "minus_resource_target",
      "parameters": [
        { "Parameter": { "res": { "name": "resource", "value": "health" } } },
        { "Parameter": { "dmg": { "name": "expression", "value": "4d6+10" } } }
      ]
    }
  }
}
```

### Common Patterns

#### Damage Action Parameters
```json
{
  "Action": {
    "sword_attack": {
      "do": "minus_resource_target",
      "parameters": [
        { "Parameter": { "p1": { "name": "resource", "value": "health" } } },
        { "Parameter": { "p2": { "name": "expression", "value": "1d8+3" } } }
      ]
    }
  }
}
```

#### Teleport Action Parameters
```json
{
  "Action": {
    "dash_forward": {
      "do": "teleport_to_radial",
      "parameters": [
        { "Parameter": { "p1": { "name": "radial", "value": "0" } } },
        { "Parameter": { "p2": { "name": "distance", "value": "150" } } }
      ]
    }
  }
}
```

#### Spawn Action Parameters
```json
{
  "Action": {
    "summon_minion": {
      "do": "spawn_actor_at_self",
      "parameters": [
        { "Parameter": { "p1": { "name": "actor", "value": "skeleton_minion" } } }
      ]
    }
  }
}
```

### Related Entities

- **Action** - Uses parameters for function execution

---

**Next:** [Resources & Measures](resources.md) | [Skills](skills.md) | [Back to Entity Overview](README.md)
