extends Entity

var name_: String
var sprite: KeyRef # Sprite
var polygon: KeyRef # Polygon # TODO remove
var base: int # Size of base
var hitbox: KeyRef # Polygon
var view: int
var on_touch: KeyRef # Action
var on_view: KeyRef # Action
var on_map_entered: KeyRef # Action
var on_map_exited: KeyRef # Action
var skills: KeyRefArray # Skill (max 9 entries)
var resources: KeyRefArray # Resource
var groups: KeyRefArray # Group
var triggers: KeyRefArray # Trigger
var timers: KeyRefArray # Timer
var strategy: KeyRef # Strategy
var speed: float

func _ready() -> void:
	tag(Group.ACTOR_ENTITY)
