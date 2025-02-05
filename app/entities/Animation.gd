extends Entity

var idle: KeyRef
var run: KeyRef
var action_1: KeyRef

func _ready() -> void:
	tag(Group.ANIMATION_ENTITY)
