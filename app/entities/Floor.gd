extends Entity

var name_: String
var location: KeyRef # Vertex
var texture: String # Path to image

func _ready() -> void:
	tag(Group.FLOOR_ENTITY)
