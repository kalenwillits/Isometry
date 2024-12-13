extends Entity

var idle: KeyRef
var run: KeyRef

func _ready() -> void:
	tag(Group.ANIMATION_ENTITY)
