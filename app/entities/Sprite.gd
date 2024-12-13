extends Entity

var animation: KeyRef
var texture: String
var size: KeyRef
var margin: KeyRef

func _ready() -> void:
	tag(Group.SPRITE_ENTITY)
