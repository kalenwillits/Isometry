extends Entity

var left: String # TODO - dice
var operator: String
var right: String # TODO - dice

func _ready() -> void:
	tag(Group.CONDITION_ENTITY)
