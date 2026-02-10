# AI System

NPC behavior is controlled through strategies containing goal-based behaviors.

## Strategy

A collection of behaviors that define how an NPC makes decisions.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `behaviors` | KeyRefArray (Behavior) | Yes | Ordered list of behaviors to evaluate |

Behaviors are evaluated in order. The first behavior whose goals are all met executes its action.

```json
{
  "Strategy": {
    "guardStrategy": {
      "behaviors": ["attackIfNear", "patrolIfIdle"]
    }
  }
}
```

## Behavior

A goal-action pair. When all goals (conditions) are true, the action executes.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `goals` | KeyRefArray (Condition) | Yes | Conditions that must all be true |
| `action` | KeyRef (Action) | Yes | Action to execute when goals met |

```json
{
  "Behavior": {
    "attackIfNear": {
      "goals": ["isNearTarget"],
      "action": "attackAction"
    },
    "patrolIfIdle": {
      "goals": ["hasNoTarget"],
      "action": "patrolAction"
    }
  }
}
```

## Common AI Patterns

### Patrol Strategy

NPCs walk between waypoints, scanning for targets:

```json
{
  "Strategy": {
    "patrolStrategy": {
      "behaviors": ["patrolBehavior"]
    }
  },
  "Behavior": {
    "patrolBehavior": {
      "goals": ["hasTarget"],
      "action": "patrolAction"
    }
  },
  "Action": {
    "patrolAction": {
      "do": "use_track",
      "then": "scanAction",
      "parameters": ["trackParam"]
    },
    "scanAction": {
      "do": "target_nearest"
    }
  }
}
```

### Follow Strategy

NPCs follow the nearest target:

```json
{
  "Strategy": {
    "followStrategy": {
      "behaviors": ["followBehavior"]
    }
  },
  "Behavior": {
    "followBehavior": {
      "goals": ["isNearTarget"],
      "action": "pursueAction"
    }
  },
  "Condition": {
    "isNearTarget": {
      "left": "@distance_to_target",
      "operator": ">",
      "right": "1"
    }
  },
  "Action": {
    "pursueAction": {
      "do": "move_to_target"
    }
  }
}
```

### Guard Strategy

NPCs stay in place, but attack if a target comes near:

```json
{
  "Strategy": {
    "guardStrategy": {
      "behaviors": ["scanBehavior", "attackBehavior"]
    }
  },
  "Behavior": {
    "scanBehavior": {
      "goals": ["hasTarget"],
      "action": "scanAction"
    },
    "attackBehavior": {
      "goals": ["isNearTarget"],
      "action": "attackAction"
    }
  }
}
```
