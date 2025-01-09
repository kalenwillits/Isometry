extends Entity

var name_: String
var sprite: KeyRef # Sprite
var polygon: KeyRef # Polygon
var hitbox: KeyRef # Polygon
var view: int
var on_touch: KeyRef # Action
var action_1: KeyRef # Action
var action_2: KeyRef # Action
var action_3: KeyRef # Action
var action_4: KeyRef # Action
var action_5: KeyRef # Action
var action_6: KeyRef # Action
var action_7: KeyRef # Action
var action_8: KeyRef # Action
var action_9: KeyRef # Actiom
var primary_action: KeyRef # Action
var resources: KeyRefArray # Resources

func _ready() -> void:
	tag(Group.ACTOR_ENTITY)
