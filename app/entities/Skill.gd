## Skill Entity
## A skill action available to an actor, typically bound to hotkeys.
##
extends Entity

## Human-readable name displayed in UI.
var name_: String
## Action triggered when skill button is pressed.
var start: KeyRef # Action
## Action triggered when skill button is released.
var end: KeyRef # Action
## Icon path for UI display in skill bar.
var icon: String
## Description text displayed in UI tooltips. Default empty.
var description: String = ""
## Maximum charge value for charging skills. 0 = no charging. Default 0.
var charge: int = 0
## Name of casting animation to play. Default empty.
var casting: String = ""

func _ready() -> void:
	tag(Group.SKILL_ENTITY)
