## Parallax Entity
## A background layer with parallax scrolling effect.
##
extends Entity

## Path to texture image file.
var texture: String
## Parallax scroll speed multiplier. Lower values = slower movement.
var effect: float

func _ready() -> void:
	tag(Group.PARALLAX_ENTITY)
