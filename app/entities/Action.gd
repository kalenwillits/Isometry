extends Entity

var name_: String
var parameters: KeyRefArray
var if_: KeyRef # Condition
var do: String # func name
var else_: KeyRef # Action
var then: KeyRef # Action
var time: float
var icon: String # Path to asset

func _ready() -> void:
	tag(Group.ACTION_ENTITY)
