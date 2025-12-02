## Timer Entity
## Executes an action at intervals or after a total duration.
##
extends Entity

## Total duration in seconds (dice expression, e.g., "60" or "2d6").
var total: String
## Interval between action executions in seconds (dice expression).
var interval: String
## Action entity to execute at intervals or completion.
var action: KeyRef # Action

func _ready() -> void:
	tag(Group.TIMER_ENTITY)
