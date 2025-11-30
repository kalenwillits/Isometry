extends Entity

var actor: KeyRef
var map: KeyRef
var notes: String = ""

func _ready() -> void:
	tag(Group.MAIN_ENTITY)
