extends Entity

var name_: String
var start: KeyRef # Action - triggered on button press
var end: KeyRef # Action - triggered on button release
var icon: String # Icon path for UI display

func _ready() -> void:
	tag(Group.SKILL_ENTITY)