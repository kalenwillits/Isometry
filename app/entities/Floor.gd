## Floor Entity
## A texture placed at a specific location on the map floor.
##
extends Entity

## Location Vertex defining floor position (x, y).
var location: KeyRef # Vertex
## Path to texture image file.
var texture: String

func _ready() -> void:
	tag(Group.FLOOR_ENTITY)
