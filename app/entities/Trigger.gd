## Trigger Entity
## Monitors a resource and executes an action when the resource changes.
##
extends Entity

## Resource entity to monitor for changes.
var resource: KeyRef # Resource
## Action entity to execute when resource changes.
var action: KeyRef # Action

func _ready() -> void:
	tag(Group.TRIGGER_ENTITY)
