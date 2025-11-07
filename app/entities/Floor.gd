extends Entity

var location: KeyRef # Vertex
var texture: String # Path to image

func _ready() -> void:
	tag(Group.FLOOR_ENTITY)
