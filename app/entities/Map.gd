## Map Entity
## A game level containing terrain, actors, and environmental elements.
##
extends Entity

## Human-readable name displayed in UI.
var name_: String
## Floor textures placed at specific locations.
var floor_: KeyRefArray # Floor
## TileMap entity defining the terrain grid.
var tilemap: KeyRef # TileMap
## Spawn point Vertex where player enters the map.
var spawn: KeyRef # Vertex
## Actor deployments defining initial actor placements.
var deployments: KeyRefArray # Deployment
## Parallax background layers.
var background: KeyRefArray # Parallax
## Background audio/music for this map.
var audio: KeyRefArray # Sound

func _ready() -> void:
	tag(Group.MAP_ENTITY)
