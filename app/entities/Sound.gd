extends Entity

var source: String
var scale: String  # Dice
var loop: bool

func _ready() -> void:
	tag(Group.SOUND_ENTITY)
