## Sprite Entity
## Visual representation configuration for actors with animation and texture data.
##
extends Entity

## Reference to AnimationSet entity containing available animations.
var animation_set: KeyRef # AnimationSet
## Path to texture/sprite sheet file.
var texture: String
## Reference to Vertex entity defining sprite dimensions (width, height).
var size: KeyRef # Vertex
## Reference to Vertex entity defining sprite margins (x, y offsets).
var margin: KeyRef # Vertex

func _ready() -> void:
	tag(Group.SPRITE_ENTITY)
