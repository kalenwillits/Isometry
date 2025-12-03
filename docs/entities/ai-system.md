# AI System Entities

Documentation for Strategy, Behavior, Trigger, and Timer entities that control NPC AI and automation.

## Table of Contents

- [Strategy Entity](#strategy-entity)
- [Behavior Entity](#behavior-entity)
- [Trigger Entity](#trigger-entity)
- [Timer Entity](#timer-entity)

## Strategy Entity

### Purpose

The **Strategy** entity defines AI decision-making for NPCs using goal-based behaviors.

### Tags

`Group.STRATEGY_ENTITY`

### Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `behaviors` | KeyRefArray | Yes | - | Ordered list of behaviors to evaluate |

### JSON Example

```json
{
  "Strategy": {
    "goblin_ai": {
      "behaviors": ["flee_if_low_health", "attack_nearest_enemy", "wander"]
    }
  },
  "Behavior": {
    "flee_if_low_health": {
      "goals": ["health_below_25"],
      "action": "run_away"
    },
    "attack_nearest_enemy": {
      "goals": ["enemy_in_range"],
      "action": "attack_target"
    },
    "wander": {
      "goals": [],
      "action": "random_movement"
    }
  }
}
```

Behaviors are evaluated in order. First matching behavior executes.

## Behavior Entity

### Purpose

The **Behavior** entity defines a goal-action pair for AI decision making.

### Tags

`Group.BEHAVIOR_ENTITY`

### Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `goals` | KeyRefArray | Yes | - | Conditions that must be met |
| `action` | KeyRef | Yes | - | Action to execute when goals satisfied |

### JSON Example

```json
{
  "Behavior": {
    "heal_when_injured": {
      "goals": ["health_below_50", "has_mana"],
      "action": "cast_heal"
    }
  },
  "Condition": {
    "health_below_50": {"left": "self.health", "operator": "<", "right": "50"},
    "has_mana": {"left": "self.mana", "operator": ">=", "right": "20"}
  },
  "Action": {
    "cast_heal": {
      "do": "plus_resource_self",
      "parameters": [
        {"Parameter": {"res": {"name": "resource", "value": "health"}}},
        {"Parameter": {"amt": {"name": "expression", "value": "30"}}}
      ]
    }
  }
}
```

## Trigger Entity

### Purpose

The **Trigger** entity monitors a resource and executes an action when it changes.

### Tags

`Group.TRIGGER_ENTITY`

### Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `resource` | KeyRef | Yes | - | Resource to monitor |
| `action` | KeyRef | Yes | - | Action to execute on change |

### JSON Example

```json
{
  "Trigger": {
    "death_trigger": {
      "resource": "health",
      "action": "on_death"
    }
  },
  "Action": {
    "on_death": {
      "do": "despawn_self",
      "if": "health_is_zero"
    }
  },
  "Condition": {
    "health_is_zero": {"left": "self.health", "operator": "==", "right": "0"}
  }
}
```

## Timer Entity

### Purpose

The **Timer** entity executes an action at intervals or after a duration.

### Tags

`Group.TIMER_ENTITY`

### Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `total` | String | Yes | - | Total duration (dice expression) |
| `interval` | String | Yes | - | Interval between executions |
| `action` | KeyRef | Yes | - | Action to execute |

### JSON Example

```json
{
  "Timer": {
    "health_regen": {
      "total": "999999",
      "interval": "3",
      "action": "regen_tick"
    }
  },
  "Action": {
    "regen_tick": {
      "do": "plus_resource_self",
      "parameters": [
        {"Parameter": {"res": {"name": "resource", "value": "health"}}},
        {"Parameter": {"amt": {"name": "expression", "value": "5"}}}
      ]
    }
  }
}
```

---

**Next:** [Visual Entities](visual-entities.md) | [Back to Entity Overview](README.md)
