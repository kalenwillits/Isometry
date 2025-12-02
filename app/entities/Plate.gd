## Plate Entity
## A text display with title and body content.
##
extends Entity

## Title text displayed prominently.
var title: String
## Body text content.
var text: String

func _ready() -> void:
	tag(Group.PLATE_ENTITY)
