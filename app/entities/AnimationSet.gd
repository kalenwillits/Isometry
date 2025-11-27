extends Entity

var name_: String
var animations: KeyRefArray # Animation

func _ready() -> void:
	tag(Group.ANIMATION_SET_ENTITY)
