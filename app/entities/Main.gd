extends Entity

var actor: KeyRef
var map: KeyRef

func _ready() -> void:
	tag(Group.MAIN_ENTITY)
