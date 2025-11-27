extends Entity

var name_: String
var start: KeyRef # Action - triggered on button press
var end: KeyRef # Action - triggered on button release
var icon: String # Icon path for UI display
var description: String = "" # Description for UI display
var charge: int = 0 # Maximum charge value (0 = no charging)
var casting: String = "" # Casting animation

func _ready() -> void:
	tag(Group.SKILL_ENTITY)
