## Layer Entity
## A rendering layer in a tilemap defining tile placement data.
##
extends Entity

## Tile placement source data identifying which tiles to place.
var source: String
## If true, enables Y-sorting for depth-based rendering.
var ysort: bool

func _ready() -> void:
	tag(Group.LAYER_ENTITY)
