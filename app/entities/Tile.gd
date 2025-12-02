## Tile Entity
## A single tile definition with navigation and rendering properties.
##
extends Entity

## Symbol identifier for this tile type.
var symbol: String
## Index in the tileset texture grid.
var index: int
## Y-sort origin offset for rendering layering.
var origin: int
## If true, tile surface is walkable and available for pathfinding.
var navigation: bool
## If true, blocks navigation on underlying tiles. Used for walls.
var obstacle: bool
## If true, tile is invisible but still functional for pathfinding/collision.
var ghost: bool

func _ready() -> void:
	tag(tile_group_name())
	tag(Group.TILE_ENTITY)
	
func tile_group_name() -> String:
	return "%s-%s" % [Group.TILE_ENTITY, symbol]
