## TileMap Entity
## A grid-based map using tiles from a tileset arranged in layers.
##
extends Entity

## TileSet entity containing tile definitions.
var tileset: KeyRef # TileSet
## Layer entities defining tile placement and rendering order.
var layers: KeyRefArray # Layer

func _ready() -> void:
	tag(Group.TILEMAP_ENTITY)
