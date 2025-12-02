## TileSet Entity
## A collection of tiles from a texture atlas arranged in a grid.
##
extends Entity

## Number of columns in the tile grid.
var columns: int
## Path to tileset texture file.
var texture: String
## Tile entities defining individual tiles in the set.
var tiles: KeyRefArray # Tile

func _ready() -> void:
	tag(Group.TILESET_ENTITY)
