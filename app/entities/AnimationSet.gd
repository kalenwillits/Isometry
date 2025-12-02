## AnimationSet Entity
## A named collection of animations for an actor.
##
extends Entity

## Human-readable animation set name.
var name_: String
## Animation entities in this set (idle, walk, attack, etc).
var animations: KeyRefArray # Animation

func _ready() -> void:
	tag(Group.ANIMATION_SET_ENTITY)
