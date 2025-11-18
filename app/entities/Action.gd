extends Entity

var name_: String
var parameters: KeyRefArray
var if_: KeyRef # Condition
var do: String # func name
var else_: KeyRef # Action
var then: KeyRef # Action
var time: float
var icon: String # Path to asset
var casting: String # Animation key name for casting state
var area: KeyRef # Polygon entity for AOE targeting (deprecated)

func _ready() -> void:
	tag(Group.ACTION_ENTITY)
