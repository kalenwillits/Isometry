extends Entity

var name_: String
var tilemap: KeyRef
var spawns: KeyRefArray
var deployments: KeyRefArray

func _ready() -> void:
	tag(Group.MAP_ENTITY)
