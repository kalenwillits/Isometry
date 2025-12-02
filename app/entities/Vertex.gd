## Vertex Entity
## A 2D coordinate point used for positions, dimensions, and polygon vertices.
##
extends Entity

## X coordinate in pixels.
var x: int
## Y coordinate in pixels.
var y: int

func _ready() -> void:
	tag(Group.VERTEX_ENTITY)
	
func to_vec2i() -> Vector2i:
	return std.vec2i_from([x, y])
