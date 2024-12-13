extends Entity

var name_: String
var parameters: KeyRefArray
var if_: KeyRef # Condition
var do: String # func name
var else_: KeyRef # Action
var then: KeyRef # ACtion

func _ready() -> void:
	tag(Group.ACTION_ENTITY)
