extends Entity

var name_: String
var keyframes: KeyRefArray # KeyFrame

func _ready() -> void:
	tag(Group.ANIMATION_ENTITY)
