extends Entity

var name_: String
var start: KeyRef # Action - triggered on button press
var end: KeyRef # Action - triggered on button release
var icon: String # Icon path for UI display

# Area targeting attributes
var radius: int = 0  # Ellipse radius for area skills
var range_: float = 0.0  # Maximum range from caster
var speed: float = 0.0  # Movement speed for area targeting
var color: String = ""  # Hex color for area overlay
var casting: String = ""  # Casting Animation
var time: float = 0.0  # Casting time
var charge: int = 0 # Maximum charge value

func _ready() -> void:
	tag(Group.SKILL_ENTITY)
