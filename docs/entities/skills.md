# Skills

Documentation for the Skill entity - player abilities bound to action slots.

## Skill Entity

### Purpose

The **Skill** entity defines player abilities that are bound to hotkeys (1-9). Skills trigger actions when activated.

### Tags

`Group.SKILL_ENTITY`

### File

`/home/kalen/Dev/atlas/app/entities/Skill.gd`

### Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `name` | String | Yes | - | Display name |
| `start` | KeyRef | No | `null` | Action on button press |
| `end` | KeyRef | No | `null` | Action on button release |
| `icon` | String | No | `""` | Icon path for UI |
| `description` | String | No | `""` | Tooltip text |
| `charge` | Int | No | `0` | Max charge value (0 = no charging) |
| `casting` | String | No | `""` | Casting animation name |

### Field Details

#### name
- **Type**: String
- **Required**: Yes
- **Description**: Display name shown on skill button and tooltips
- **Example**: `"Fireball"`, `"Heal"`, `"Dash"`

#### start
- **Type**: KeyRef to Action entity
- **Required**: No (but at least one of start/end should be defined)
- **Default**: `null`
- **Description**: Action executed when skill button is pressed
- **Use**: Instant casts, damage, most abilities

#### end
- **Type**: KeyRef to Action entity
- **Required**: No
- **Default**: `null`
- **Description**: Action executed when skill button is released
- **Use**: Charged abilities, toggle effects, releasing skills

#### icon
- **Type**: String (file path)
- **Required**: No
- **Default**: `""`
- **Description**: Path to icon image for skill button
- **Example**: `"assets/icons/fireball.png"`

#### description
- **Type**: String
- **Required**: No
- **Default**: `""`
- **Description**: Tooltip text explaining the skill

#### charge
- **Type**: Int
- **Required**: No
- **Default**: `0`
- **Description**: Maximum charge value. If 0, skill doesn't charge. If > 0, skill charges while held.
- **Use**: Charged attacks, bow drawing, spell channeling

#### casting
- **Type**: String
- **Required**: No
- **Default**: `""`
- **Description**: Name of animation to play while casting
- **Example**: `"casting"`, `"channeling"`

### JSON Example - Instant Cast

```json
{
  "Skill": {
    "fireball": {
      "name": "Fireball",
      "start": "fireball_action",
      "icon": "assets/icons/fireball.png",
      "description": "Launch a fiery projectile dealing 4d6+10 fire damage.",
      "charge": 0
    }
  },
  "Action": {
    "fireball_action": {
      "do": "area_of_effect_at_target",
      "parameters": [
        { "Parameter": { "act": { "name": "action", "value": "fire_damage" } } },
        { "Parameter": { "rad": { "name": "radius", "value": "80" } } }
      ]
    },
    "fire_damage": {
      "do": "minus_resource_target",
      "parameters": [
        { "Parameter": { "res": { "name": "resource", "value": "health" } } },
        { "Parameter": { "dmg": { "name": "expression", "value": "4d6+10" } } }
      ]
    }
  }
}
```

### JSON Example - Charged Skill

```json
{
  "Skill": {
    "power_shot": {
      "name": "Power Shot",
      "start": "start_charging",
      "end": "release_arrow",
      "icon": "assets/icons/bow.png",
      "description": "Hold to charge, release to fire a powerful arrow.",
      "charge": 100,
      "casting": "bow_draw"
    }
  },
  "Action": {
    "start_charging": {
      "do": "echo",
      "parameters": [
        { "Parameter": { "msg": { "name": "message", "value": "Charging..." } } }
      ]
    },
    "release_arrow": {
      "do": "minus_resource_target",
      "parameters": [
        { "Parameter": { "res": { "name": "resource", "value": "health" } } },
        { "Parameter": { "dmg": { "name": "expression", "value": "3d10+charge" } } }
      ]
    }
  }
}
```

### Action Slot Limit

**Maximum:** 9 skills per actor (bound to keys 1-9)

```json
{
  "Actor": {
    "mage": {
      "skills": [
        "fireball",      // Key 1
        "ice_blast",     // Key 2  
        "lightning",     // Key 3
        "teleport",      // Key 4
        "shield",        // Key 5
        "heal",          // Key 6
        "mana_drain",    // Key 7
        "meteor",        // Key 8
        "time_stop"      // Key 9
      ]
    }
  }
}
```

### Skill Patterns

#### Damage Skill
```json
{
  "Skill": {
    "sword_slash": {
      "name": "Sword Slash",
      "start": "slash_action",
      "icon": "assets/icons/sword.png",
      "description": "A quick sword strike dealing 1d8+3 damage."
    }
  },
  "Action": {
    "slash_action": {
      "do": "minus_resource_target",
      "parameters": [
        { "Parameter": { "res": { "name": "resource", "value": "health" } } },
        { "Parameter": { "dmg": { "name": "expression", "value": "1d8+3" } } }
      ]
    }
  }
}
```

#### Heal Skill
```json
{
  "Skill": {
    "healing_light": {
      "name": "Healing Light",
      "start": "heal_action",
      "icon": "assets/icons/heal.png",
      "description": "Restore 3d8+5 health to target ally."
    }
  },
  "Action": {
    "heal_action": {
      "do": "plus_resource_target",
      "parameters": [
        { "Parameter": { "res": { "name": "resource", "value": "health" } } },
        { "Parameter": { "amt": { "name": "expression", "value": "3d8+5" } } }
      ]
    }
  }
}
```

#### Movement Skill
```json
{
  "Skill": {
    "dash": {
      "name": "Dash",
      "start": "dash_forward",
      "icon": "assets/icons/dash.png",
      "description": "Quickly dash forward 150 pixels."
    }
  },
  "Action": {
    "dash_forward": {
      "do": "teleport_to_radial",
      "parameters": [
        { "Parameter": { "rad": { "name": "radial", "value": "0" } } },
        { "Parameter": { "dist": { "name": "distance", "value": "150" } } }
      ]
    }
  }
}
```

#### Toggle Skill
```json
{
  "Skill": {
    "defensive_stance": {
      "name": "Defensive Stance",
      "start": "activate_defense",
      "end": "deactivate_defense",
      "icon": "assets/icons/shield.png",
      "description": "Toggle defensive stance. Press to activate, release to deactivate."
    }
  },
  "Action": {
    "activate_defense": {
      "do": "set_speed_self",
      "parameters": [
        { "Parameter": { "spd": { "name": "speed", "value": "50" } } }
      ]
    },
    "deactivate_defense": {
      "do": "set_speed_self",
      "parameters": [
        { "Parameter": { "spd": { "name": "speed", "value": "200" } } }
      ]
    }
  }
}
```

### Related Entities

- **Actor** - Skills are assigned to actors
- **Action** - Skills trigger actions
- **Animation** - Casting animations

---

**Next:** [AI System](ai-system.md) | [Visual Entities](visual-entities.md) | [Back to Entity Overview](README.md)
