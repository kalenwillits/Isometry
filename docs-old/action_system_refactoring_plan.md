# Action System Refactoring: Detailed Implementation Plan

## Overview
Transform the hardcoded action_1-9 system into a flexible skills-based system with start/end actions and dynamic animation states, while maintaining the 9-action limit.

## Phase 1: Create New Skill Entity

### 1.1 Create Skill Entity
**File**: `/app/entities/Skill.gd` (NEW)
```gdscript
extends Entity

var name_: String
var start: KeyRef # Action - triggered on button press
var end: KeyRef # Action - triggered on button release

func _ready() -> void:
    tag(Group.SKILL_ENTITY)
```

### 1.2 Update Group Constants
**File**: `/app/autoload/group.gd`
- Add `SKILL_ENTITY` constant

## Phase 2: Update Actor Entity Structure

### 2.1 Replace Action Properties in Actor Entity
**File**: `/app/entities/Actor.gd`
**Lines to Remove**: 13-21
```gdscript
# REMOVE these lines:
var action_1: KeyRef # Action
var action_2: KeyRef # Action
var action_3: KeyRef # Action
var action_4: KeyRef # Action
var action_5: KeyRef # Action
var action_6: KeyRef # Action
var action_7: KeyRef # Action
var action_8: KeyRef # Action
var action_9: KeyRef # Actiom
```

**Lines to Add**: After line 12
```gdscript
var skills: KeyRefArray # Skill (max 9 entries)
```

## Phase 3: Refactor KeyFrames System

### 3.1 Update KeyFrames Class
**File**: `/app/classes/KeyFrames.gd`
**Lines to Remove**: 9-17, 25-33
```gdscript
# REMOVE these constants:
const ACTION_1: String = "action_1"
const ACTION_2: String = "action_2"
const ACTION_3: String = "action_3"
const ACTION_4: String = "action_4"
const ACTION_5: String = "action_5"
const ACTION_6: String = "action_6"
const ACTION_7: String = "action_7"
const ACTION_8: String = "action_8"
const ACTION_9: String = "action_9"
```

**Update list() function**: Lines 19-34
```gdscript
# Keep only base states
static func list() -> Array[String]:
    return [
        IDLE,
        WALK, 
        RUN, 
        DEAD
    ]
```

### 3.2 Add Dynamic Animation Support
**File**: `/app/classes/KeyFrames.gd`
Add new function:
```gdscript
static func is_valid_animation(animation_name: String) -> bool:
    return animation_name in list() or animation_name != ""
```

## Phase 4: Update Actor Scene Logic

### 4.1 Replace Hardcoded Signals
**File**: `/app/scenes/actor.gd`
**Lines to Remove**: 80-88
```gdscript
# REMOVE these signal declarations:
signal action_1(actor)
signal action_2(actor)
signal action_3(actor)
signal action_4(actor)
signal action_5(actor)
signal action_6(actor)
signal action_7(actor)
signal action_8(actor)
signal action_9(actor)
```

**Lines to Add**: After line 79
```gdscript
# Dynamic skill signals will be created at runtime
var skill_signals: Dictionary = {}
```

### 4.2 Refactor use_actions() Function
**File**: `/app/scenes/actor.gd`
**Lines to Replace**: 495-522
```gdscript
# REPLACE entire use_actions() function:
func use_actions() -> void:
    var actor_ent = Repo.select(actor)
    if !actor_ent or !actor_ent.skills: return
    
    # Limit to 9 skills maximum to maintain action_1-9 compatibility
    var skills_list = actor_ent.skills.lookup()
    var max_skills = min(skills_list.size(), 9)
    
    for i in range(max_skills):
        var skill_ent = skills_list[i]
        var action_name = "action_%d" % (i + 1)
        
        # Handle skill start (button press)
        if Input.is_action_just_pressed(action_name) and skill_ent.start:
            emit_skill_signal("%s_start" % skill_ent.key(), resolve_target())
            
        # Handle skill end (button release)
        if Input.is_action_just_released(action_name) and skill_ent.end:
            emit_skill_signal("%s_end" % skill_ent.key(), resolve_target())

func emit_skill_signal(skill_event: String, target_actor: Actor) -> void:
    if skill_signals.has(skill_event):
        skill_signals[skill_event].emit(target_actor)
```

### 4.3 Update Actor Builder for Skills
**File**: `/app/scenes/actor.gd`
**Lines to Replace**: 162-164
```gdscript
# REPLACE the hardcoded action building:
# OLD:
for n in range(1, 10):
    var action_name: String = "action_%d" % n
    if actor_ent.get(action_name): this.build_action(actor_ent.get(action_name).key(), n)

# NEW:
if actor_ent.skills:
    var skills_list = actor_ent.skills.lookup()
    var max_skills = min(skills_list.size(), 9)  # Limit to 9 skills
    for i in range(max_skills):
        var skill_ent = skills_list[i]
        this.build_skill(skill_ent, i + 1)
```

### 4.4 Replace build_action with build_skill
**File**: `/app/scenes/actor.gd`
**Lines to Replace**: 674-686
```gdscript
# REPLACE build_action function:
func build_skill(skill_ent: Entity, slot_number: int) -> void:
    # Create dynamic signals for this skill
    var start_signal_name = "%s_start" % skill_ent.key()
    var end_signal_name = "%s_end" % skill_ent.key()
    
    # Add signals to tracking dictionary
    if !skill_signals.has(start_signal_name):
        skill_signals[start_signal_name] = Signal()
        add_user_signal(start_signal_name, [{"name": "target_actor", "type": TYPE_OBJECT}])
    if !skill_signals.has(end_signal_name):
        skill_signals[end_signal_name] = Signal()
        add_user_signal(end_signal_name, [{"name": "target_actor", "type": TYPE_OBJECT}])
    
    # Connect start action
    if skill_ent.start:
        connect(start_signal_name, func(target_actor): _local_action_handler(
            target_actor, 
            func(target_entity): 
                var target_name: String = target_entity.name if target_entity else ""
                get_tree().get_first_node_in_group(Group.ACTIONS).invoke_action.rpc_id(1, skill_ent.start.key(), name, target_name),
            skill_ent.start.lookup()))
    
    # Connect end action
    if skill_ent.end:
        connect(end_signal_name, func(target_actor): _local_action_handler(
            target_actor, 
            func(target_entity): 
                var target_name: String = target_entity.name if target_entity else ""
                get_tree().get_first_node_in_group(Group.ACTIONS).invoke_action.rpc_id(1, skill_ent.end.key(), name, target_name),
            skill_ent.end.lookup()))
```

### 4.5 Update Animation System
**File**: `/app/scenes/actor.gd`
**Lines to Update**: 1211-1213
```gdscript
# UPDATE use_animation function:
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

## Phase 5: Update Animation Entity

### 5.1 Remove Hardcoded Action Animations
**File**: `/app/entities/Animation.gd`
**Lines to Remove**: 5
```gdscript
# REMOVE:
var action_1: KeyRef
```

**Lines to Add**: After line 4
```gdscript
# Animation states will be handled by Action entities when they execute
# Animation entity now only needs base states: idle, run, walk, dead
```

## Phase 6: Update KeyBinds System

### 6.1 Keep Action Bindings (No Changes Needed)
**File**: `/app/autoload/keybinds.gd`
- Keep existing ACTION_1 through ACTION_9 constants and bindings
- No changes needed since we maintain 9-action limit

## Phase 7: Update UI System

### 7.1 Update Action UI References
**File**: `/app/scenes/actor.gd`
**Lines to Update**: 339-344
```gdscript
# UPDATE action UI rendering:
if is_primary():
    var actor_ent = Repo.select(actor)
    if actor_ent and actor_ent.skills:
        var skills_list = actor_ent.skills.lookup()
        var max_skills = min(skills_list.size(), 9)  # Limit to 9 for UI compatibility
        for i in range(max_skills):
            var skill_ent = skills_list[i]
            var slot_number = i + 1
            Queue.enqueue(
                Queue.Item.builder()
                .comment("Schedule render new skill_%s for actor %s" % [slot_number, name])
                .task(func(): Finder.select(Group.UI_ACTION_BLOCK_N % slot_number).render(skill_ent.key()))
                .build()
            )
```

## Phase 8: Project Configuration (No Changes Needed)

### 8.1 Input Map Compatibility Maintained
**File**: `/app/project.godot`
- Keep existing action_1-9 input definitions
- No changes needed since we maintain the 9-action structure

## Benefits of This Refactoring

1. **Start/End Semantics**: Campaign creators see intuitive "start" and "end" actions
2. **Dynamic Animations**: Action entities can define custom animation states when executed
3. **Cleaner Code**: Eliminates hardcoded repetition while maintaining structure
4. **Better Organization**: Skills are self-contained entities that reference Actions
5. **Full Backwards Compatibility**: All existing systems continue to work
6. **Maintained Limits**: Respects 9-action UI and input constraints

## 9-Action Limit Implementation Details

### Validation in Actor Builder
```gdscript
# In actor.gd ActorBuilder
func skills(value: KeyRefArray) -> ActorBuilder:
    # Validate maximum 9 skills
    if value.lookup().size() > 9:
        Logger.warn("Actor skills limited to maximum of 9. Truncating skills array.")
        # Truncate to first 9 skills
        var truncated_skills = value.lookup().slice(0, 9)
        # Create new KeyRefArray with truncated list
        this.skills = KeyRefArray.new()
        for skill in truncated_skills:
            this.skills.append(skill.key())
    else:
        this.skills = value
    return self
```

### UI Compatibility
- Action blocks 1-9 remain unchanged
- Skill slots map directly to action_1 through action_9
- Empty skill slots show as disabled/empty action blocks

## Migration Strategy

1. Implement new Skill entity
2. Update Actor entity structure with validation
3. Refactor core action system with 9-skill limit
4. Test with existing campaigns
5. Document new skill creation process for campaign creators

## Files Modified

- `/app/entities/Skill.gd` (NEW)
- `/app/entities/Actor.gd` - Replace action_1-9 with skills array (max 9)
- `/app/scenes/actor.gd` - Major refactoring of action system with limits
- `/app/classes/KeyFrames.gd` - Remove ACTION_1-9 constants
- `/app/entities/Animation.gd` - Remove hardcoded action reference
- `/app/autoload/group.gd` - Add SKILL_ENTITY constant

## Current Status
This refactoring transforms the action system from:
```gdscript
# Old system - hardcoded and limited
var action_1: KeyRef # Action
if Input.is_action_just_released("action_1"):
    set_state(KeyFrames.ACTION_1)
    emit_signal("action_1", resolve_target())
```

To:
```gdscript
# New system - flexible while maintaining 9-action limit
var skills: KeyRefArray # Skill (max 9 entries)
for i in range(min(skills.size(), 9)):
    var skill = skills[i]
    var action_name = "action_%d" % (i + 1)
    if Input.is_action_just_pressed(action_name) and skill.start:
        emit_skill_signal("%s_start" % skill.key(), resolve_target())
    if Input.is_action_just_released(action_name) and skill.end:
        emit_skill_signal("%s_end" % skill.key(), resolve_target())
```

This provides campaign creators with intuitive "start/end" semantics while maintaining full backwards compatibility and the 9-action limit.