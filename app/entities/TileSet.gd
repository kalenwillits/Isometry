extends Entity

var columns: int
var texture: String
var tiles: KeyRefArray

func _ready() -> void:
	tag(Group.TILESET_ENTITY)
