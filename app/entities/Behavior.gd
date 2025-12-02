## Behavior Entity
## A goal-action pair for AI decision making.
##
extends Entity

## Condition entities that must be met to activate this behavior.
var goals: KeyRefArray # Condition
## Action entity to execute when goals are satisfied.
var action: KeyRef # Action

func _ready() -> void:
	tag(Group.BEHAVIOR_ENTITY)
