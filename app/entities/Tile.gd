extends Entity

var symbol: String
var index: int
var origin: int # Ysort origin
var navigation: bool # if true, the surface of this tile will be available for pathing. This should be true for any floor tile
var obstacle: bool # if true, this will disable any navigation tile that it's on top of. Used for placing walls.

func _ready() -> void:
	tag(tile_group_name())
	tag(Group.TILE_ENTITY)
	
func tile_group_name() -> String:
	return "%s-%s" % [Group.TILE_ENTITY, symbol]
