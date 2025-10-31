extends Entity

var name_: String
var parameters: KeyRefArray
var if_: KeyRef # Condition
var do: String # func name
var else_: KeyRef # Action
var then: KeyRef # Action
var time: float
var icon: String # Path to asset
var area: KeyRef # Polygon entity for AOE targeting
var speed: float # Movement speed of area targeting cursor

func _ready() -> void:
	tag(Group.ACTION_ENTITY)
