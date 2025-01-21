extends Entity

var behaviors: KeyRefArray # Behavior

func _ready() -> void:
	tag(Group.STRATEGY_ENTITY)
