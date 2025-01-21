extends Entity

var criteria: KeyRef # Condition
var action: KeyRef # Action

func _ready() -> void:
	tag(Group.BEHAVIOR_ENTITY)
