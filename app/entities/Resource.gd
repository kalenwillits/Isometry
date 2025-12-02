## Resource Entity
## A trackable numeric value associated with an actor (health, mana, stamina, etc).
##
extends Entity

## Human-readable name displayed in UI.
var name_: String
## Default starting value.
var default: int
## Minimum allowed value.
var min_: int
## Maximum allowed value.
var max_: int
## Icon path for UI display.
var icon: String
## Visibility threshold. Resource only visible when value >= reveal. 0 = always visible.
var reveal: int
## Menu entity for interaction options.
var menu: KeyRef # Menu
## Description text displayed in UI.
var description: String

func _ready() -> void:
	tag(Group.RESOURCE_ENTITY)
