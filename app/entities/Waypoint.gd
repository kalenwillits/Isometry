extends Entity

var name_: String
var location: KeyRef # Vertex
var icon: String
var map: KeyRef # Map
var menu: KeyRef # Menu
var description: String

func _ready() -> void:
	tag(Group.WAYPOINT_ENTITY)
