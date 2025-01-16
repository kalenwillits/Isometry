extends Entity

var resource: KeyRef # Resource
var action: KeyRef # Action

func _ready() -> void:
	tag(Group.TRIGGER_ENTITY)
