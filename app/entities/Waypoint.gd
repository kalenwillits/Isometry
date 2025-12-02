## Waypoint Entity
## A discoverable fast-travel location on a map.
##
extends Entity

## Human-readable waypoint name.
var name_: String
## Vertex entity defining waypoint position (x, y).
var location: KeyRef # Vertex
## Icon path for map and UI display.
var icon: String
## Map entity this waypoint belongs to.
var map: KeyRef # Map
## Menu entity for waypoint interaction options.
var menu: KeyRef # Menu
## Description text displayed in UI.
var description: String

func _ready() -> void:
	tag(Group.WAYPOINT_ENTITY)
