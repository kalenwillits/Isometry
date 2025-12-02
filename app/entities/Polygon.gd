## Polygon Entity
## A closed shape defined by an ordered array of vertices.
##
extends Entity

## Ordered array of Vertex entities defining polygon boundary.
var vertices: KeyRefArray # Vertex

func _ready() -> void:
	tag(Group.POLYGON_ENTITY)
