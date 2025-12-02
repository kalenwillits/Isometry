## Menu Entity
## A collection of action options for interaction.
##
extends Entity

## Human-readable menu name.
var name_: String
## Action entities available in this menu.
var actions: KeyRefArray # Action

func _ready() -> void:
	tag(Group.MENU_ENTITY)
