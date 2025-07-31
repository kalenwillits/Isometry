# Atlas Project Outline

Atlas is a pixel art isometric multiplayer game framework written in Godot 4.2.

# Network
The atlas application is able to act as a Client, Server, or Host. 
The client, connects to either a server or host.
The Server is able to take connections from clients, but is meant to be run in headless mode and does not allow anyone to participate in the game while the application is running in server mode.
The Host accepts client connections and allows someone running the game in host mode to play along with their clients. That way there is no need for a server. 


# Custom Maps
The core principal of atlas is that everything is easily customizable from the map file by editing simple JSON files. 
Similar to the relationship of Dungeons & Dragons with homebrew content, the content can change but the rules stay the same.

# Maps
Maps are built off of a .zip file full of files. 
The app reads them in from a .json file and loads them. 
const _entities: Dictionary = {
	"Main": preload("res://entities/Main.gd"), # The main entrypoint of the map with some global settings
	"Action": preload("res://entities/Action.gd"), # A action that can occur to alter resources between actors. 
	"Actor": preload("res://entities/Actor.gd"), # An actor -- either player or npc controlled. 
	"Deployment": preload("res://entities/Deployment.gd"), # THe position where non-player actors are placed on a map.
	"Polygon": preload("res://entities/Polygon.gd"), # A 2d polygon representation to be used for different purposes. Such as player hit-boxes.
	"Sprite": preload("res://entities/Sprite.gd"), # The actual image a sprite renders.
	"TileSet": preload("res://entities/TileSet.gd"), # Data about the tileset used on a map. 
	"Layer": preload("res://entities/Layer.gd"), #  A layer of tiles on a tilemap.
	"Resource": preload("res://entities/Resource.gd"), # a named integer representation of a quantity used by all actors. such as HP, mana, GOLD, lumber, etc...
	"Tile": preload("res://entities/Tile.gd"), # A tile from a tile set
	"Vertex": preload("res://entities/Vertex.gd"), # A 2d point to assist in creating polygons or deployments.
	"Animation": preload("res://entities/Animation.gd"), # The sequence from sprite sheet and names of each animation
	"Map": preload("res://entities/Map.gd"), # Meta data about the map
	"TileMap": preload("res://entities/TileMap.gd"), # The tilemap to be used
	"KeyFrame": preload("res://entities/KeyFrame.gd"), # Animation key frames
	"Parameter": preload("res://entities/Parameter.gd"), # Abstract parameter to be used in actions
	"Condition": preload("res://entities/Condition.gd"), # if this equals that then execute definition. Useful for chaining actions
	"Group": preload("res://entities/Group.gd"), # Used for tab-targeting groups.  Helpful when there is a map with lots of different types of actors
	"Trigger": preload("res://entities/Trigger.gd"), # Triggers can be placed on actors with a few key word events that can activate them. -- Such as on touch, on death, on equip item, on resource change etc...
	"Timer": preload("res://entities/Timer.gd"), # Abstract timer to trigger actions  -- such as health regeneration
	"Strategy": preload("res://entities/Strategy.gd"), # Used for NPC AI
	"Behavior": preload("res://entities/Behavior.gd"), # A single thing to do as an NPC
	"Measure": preload("res://entities/Measure.gd"), # A view of resources calculated but never stored
	"Parallax": preload("res://entities/Parallax.gd"), # PArralax background
	"Sound": preload("res://entities/Sound.gd"), # A sound file to be played by an action
}
}

# Gameplay
The gameplay is pixel art isometric where a player controls a single actor. 
The player can then interact with other actors on the map via actions

It is meant to be an RPG played like a MOBA with extreme custom content support

● This is Atlas, a tabletop RPG platform built with Godot 4. Based on the
  codebase structure, here's my understanding:

  Core Purpose: Atlas is a digital tabletop RPG platform that allows
  players to run campaigns with networked multiplayer support, featuring a
  tile-based map system with actors, resources, and action management.

  Key Features:
  - Godot 4 Game Engine with GDScript and C++ extensions (using godot-cpp)
  - Multiplayer networking with client-server architecture
  - Campaign system with map loading and management
  - Actor-based gameplay with movement, targeting, and action systems
  - Resource management system with public/private/secret visibility
  - Dice rolling engine (C++ extension) with algebraic expressions
  - Real-time communication and synchronization between players
  - Controller/keyboard input with 9 action slots and targeting system

  Technical Architecture:
  - Uses Godot's autoload singleton pattern for core systems (networking,
  routing, logging, etc.)
  - C++ extensions for performance-critical dice mechanics
  - Tile-based rendering with line-of-sight calculations
  - Scene-based UI management with transitions

  This appears to be a sophisticated digital tabletop platform designed for
   running D&D-style campaigns with multiple networked players, combining
  the flexibility of traditional tabletop gaming with digital convenience
  and automation.
