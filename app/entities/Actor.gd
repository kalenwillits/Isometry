extends Entity

var name_: String
var sprite: KeyRef # Sprite
var polygon: KeyRef # Polygon
var hitbox: KeyRef # Polygon
var on_touch: KeyRef # Action
var resources: KeyRefArray # Resources

func _ready() -> void:
	tag(Group.ACTOR_ENTITY)
