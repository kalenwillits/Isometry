## Group Entity
## A faction or team with visual identification color.
##
extends Entity

## Human-readable group name.
var name_: String
## Hex color code for actor outline and UI display.
var color: String

func _ready() -> void:
	tag(Group.GROUP_ENTITY)
