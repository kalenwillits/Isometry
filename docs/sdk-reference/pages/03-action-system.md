# Action System

Actions are the execution engine of Isometry. Every interaction, skill use, and AI behavior ultimately triggers an action.

## Action

Defines an executable command with optional conditions and chaining.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | String | No | Display name |
| `do` | String | Yes | Function to execute (see Action Functions below) |
| `parameters` | KeyRefArray (Parameter) | No | Arguments passed to the function |
| `time` | float | No | Execution time in seconds (0 = instant) |
| `animation` | KeyRef (Animation) | No | Animation to play (requires time > 0) |
| `if` | KeyRef (Condition) | No | Condition to check before execution |
| `then` | KeyRef (Action) | No | Action to execute after `do` completes (if condition passes) |
| `else_` | KeyRef (Action) | No | Action if condition fails |

### Execution Flow

1. If `if` is set, evaluate the condition
2. If condition passes (or no condition), execute `do` with `parameters`
3. If `animation` is set and `time` > 0, play the animation
4. After completion, execute `then` if set
5. If condition failed, execute `else_` if set

```json
{
  "Action": {
    "smartHeal": {
      "name": "Smart Heal",
      "if": "isHurt",
      "do": "plus_resource_self",
      "then": "healMessage",
      "else_": "fullHealthMessage",
      "parameters": ["healthParam", "healAmount"]
    }
  }
}
```

## Condition

Boolean comparison used by actions for conditional logic.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `left` | String | Yes | Left operand (value or `@variable`) |
| `operator` | String | Yes | Comparison: `=`, `!=`, `<`, `>`, `<=`, `>=` |
| `right` | String | Yes | Right operand (value or `@variable`) |

The `@` prefix accesses actor properties:
- `@health` - Current health resource value
- `@mana` - Current mana resource value
- `@has_target` - 1 if actor has a target, 0 otherwise
- `@distance_to_target` - Distance to current target
- `@distance_to_destination` - Distance to movement destination

```json
{
  "Condition": {
    "isHurt": {
      "left": "@health",
      "operator": "<",
      "right": "20"
    },
    "isDead": {
      "left": "@health",
      "operator": "<=",
      "right": "0"
    }
  }
}
```

## Parameter

Name-value pairs passed to action functions.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | String | Yes | Parameter name (must match function argument) |
| `value` | String | Yes | Parameter value (string, number, or dice expression) |

```json
{
  "Parameter": {
    "healthParam": { "name": "resource", "value": "health" },
    "damageRoll": { "name": "expression", "value": "(1d6)-1" }
  }
}
```

### Dice Expressions

Parameters that accept expressions support dice notation:

- `1d6` - Roll one six-sided die
- `2d8+3` - Roll two eight-sided dice, add 3
- `(1d4)-1` - Roll one four-sided die, subtract 1
- `50+(1d100)` - 50 plus a d100 roll

## Skill

Player abilities bound to hotbar keys (1-9).

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | String | No | Display name |
| `start` | KeyRef (Action) | No | Action on key press |
| `end` | KeyRef (Action) | No | Action on key release |
| `icon` | String | No | Icon path for hotbar display |
| `description` | String | No | Tooltip text |
| `charge` | int | No | Max charge for held skills (0 = instant) |
| `casting` | String | No | Casting animation name |

```json
{
  "Skill": {
    "fireballSkill": {
      "name": "Fireball",
      "start": "fireballAction",
      "end": "fireballAction",
      "icon": "/assets/icons/fireball.png",
      "description": "Hurl a ball of fire at your target."
    }
  }
}
```

## Common Action Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `echo` | Display a message | `message` |
| `plus_resource_self` | Add to own resource | `resource`, `expression` |
| `minus_resource_self` | Subtract from own resource | `resource`, `expression` |
| `plus_resource_target` | Add to target's resource | `resource`, `expression` |
| `minus_resource_target` | Subtract from target's resource | `resource`, `expression` |
| `move_to_target` | Move toward current target | (none) |
| `move_map_target` | Move target to another map | `map`, `location` |
| `move_map_self` | Move self to another map | `map`, `location` |
| `set_destination_self` | Set movement destination | `location` |
| `target_nearest` | Target the nearest visible actor | (none) |
| `change_strategy` | Change AI strategy | `strategy` |
| `open_plate` | Display a text plate | `plate` |
| `use_track` | Follow a patrol track | `track` |
