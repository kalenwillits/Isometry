extends Entity

var default: int
var min_: int
var max_: int
var icon: String

func _ready() -> void:
	tag(Group.RESOURCE_ENTITY)
