extends Entity

var tileset: KeyRef
var layers: KeyRefArray

func _ready() -> void:
	tag(Group.TILEMAP_ENTITY)
