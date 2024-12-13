extends Entity

var x: int
var y: int

func _ready() -> void:
	tag(Group.VERTEX_ENTITY)
	
func to_vec2i() -> Vector2i:
	return std.vec2i_from([x, y])
