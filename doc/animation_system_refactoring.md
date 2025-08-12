# Animation System Refactoring: Dynamic Keyframes

## Overview
Refactored the Animation entity from hardcoded animation properties (idle, walk, run, dead) to a dynamic keyframes array system, allowing unlimited custom animations.

## Changes Made

### 1. Updated Animation Entity
**File**: `/app/entities/Animation.gd`

**Old Structure**:
```gdscript
extends Entity

var idle: KeyRef
var walk: KeyRef
var run: KeyRef
var dead: KeyRef
```

**New Structure**:
```gdscript
extends Entity

var name_: String
var keyframes: KeyRefArray # KeyFrame
```

### 2. Updated Animation Building Logic
**File**: `/app/scenes/actor.gd`

#### Audio Building (lines 242-250)
- Changed from looping `KeyFrames.list()` to iterating through `animation_ent.keyframes.lookup()`
- Uses `keyframe_ent.key()` as the state name
- Dynamically builds audio for any animation state

#### Sprite Building (lines 974-991)
- Changed from hardcoded keyframe property access to dynamic keyframes array iteration
- Builds sprite animations for any keyframe in the array
- Added safety check for radial direction existence

### 3. Enhanced Animation System
**File**: `/app/classes/KeyFrames.gd`

Added helper functions:
```gdscript
static func is_valid_animation(animation_name: String) -> bool:
    return animation_name in list() or animation_name != ""

static func get_base_animation_names() -> Array[String]:
    # Returns base animation names that should always be available
    return list()
```

### 4. Improved Animation Fallback
**File**: `/app/scenes/actor.gd` (lines 1224-1233)

Enhanced `use_animation()` with fallback logic:
```gdscript
func use_animation():
    # Support both static KeyFrames and dynamic skill animations
    var animation_key = "%s:%s" % [state, heading]
    if $Sprite.sprite_frames.has_animation(animation_key):
        $Sprite.animation = animation_key
    else:
        # Fallback to idle if animation doesn't exist
        var idle_key = "%s:%s" % [KeyFrames.IDLE, heading]
        if $Sprite.sprite_frames.has_animation(idle_key):
            $Sprite.animation = idle_key
```

### 5. Fixed Deployment Entity
**File**: `/app/entities/Deployment.gd`
- Fixed incorrect `Group.ANIMATION_ENTITY` tag to proper `Group.DEPLOYMENT_ENTITY`

## Benefits

### For Campaign Creators:
1. **Unlimited Animations**: No longer limited to 4 base states (idle, walk, run, dead)
2. **Custom Animation Names**: Can create animations with any meaningful names
3. **Flexible Animation Sets**: Different actors can have completely different animation sets
4. **Action-Driven Animations**: Actions can trigger any custom animation state

### Technical Benefits:
1. **Dynamic System**: Animation building adapts to any number of keyframes
2. **Robust Fallback**: Graceful degradation when animations don't exist
3. **Future-Proof**: Easy to extend with new animation features
4. **Clean Architecture**: Separation of animation definition from usage

## Migration Path

### Old System:
```gdscript
# Animation entity had hardcoded properties
animation_ent.idle.lookup()  # KeyFrame reference
animation_ent.walk.lookup()  # KeyFrame reference
animation_ent.run.lookup()   # KeyFrame reference
animation_ent.dead.lookup()  # KeyFrame reference
```

### New System:
```gdscript
# Animation entity has dynamic keyframes array
for keyframe_ref in animation_ent.keyframes.lookup():
    var keyframe_ent = keyframe_ref
    var animation_name = keyframe_ent.key()
    # Build animation for any state name
```

## Backward Compatibility

The system maintains backward compatibility through:
1. **Base Animation Support**: `KeyFrames.list()` still provides core animation names
2. **Fallback Logic**: Missing animations fall back to idle
3. **State System**: Existing state management unchanged
4. **Input System**: Action triggering continues to work normally

## Integration with Skill System

This refactoring perfectly complements the skill system refactoring:
1. **Skills trigger Actions**: Skills define start/end action triggers
2. **Actions set Animation States**: Actions can set any custom animation state
3. **Dynamic Animation Building**: Animation system builds any state referenced by actions
4. **Flexible Animation Sets**: Different actor types can have completely different animation sets

## Example Usage

Campaign creators can now define:
```gdscript
# Attack skill triggers "sword_swing" action
# Action sets state to "attacking" 
# Animation entity has "attacking" keyframe in keyframes array
# Sprite system builds "attacking:N", "attacking:S", etc. animations
```

This provides complete flexibility while maintaining the simple, intuitive interface for campaign creators.