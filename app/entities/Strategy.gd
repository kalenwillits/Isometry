## Strategy Entity
## AI behavior strategy defining goal-based decision making.
##
extends Entity

## Behavior entities evaluated to determine AI actions.
var behaviors: KeyRefArray # Behavior

func _ready() -> void:
	tag(Group.STRATEGY_ENTITY)
