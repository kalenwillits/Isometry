extends Entity

var name_: String
var actions: KeyRefArray # Action

func _ready() -> void:
	tag(Group.MENU_ENTITY)
