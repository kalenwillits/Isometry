extends Entity

var goals: KeyRefArray # Condition
var action: KeyRef # Action

func _ready() -> void:
	tag(Group.BEHAVIOR_ENTITY)
