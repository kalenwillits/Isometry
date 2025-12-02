## Actor Entity
## A controllable or AI-driven character in the game world.
##
extends Entity

## Human-readable name displayed in UI.
var name_: String
## Reference to Sprite entity for visual representation.
var sprite: KeyRef # Sprite
## Size of actor's base circle in pixels.
var base: int
## Collision polygon for physics interactions.
var hitbox: KeyRef # Polygon
## Vision range in pixels for detecting other actors.
var perception: int
## Detection difficulty for other actors (higher = more visible).
var salience: int
## Action triggered when another actor touches this actor.
var on_touch: KeyRef # Action
## Action triggered when this actor is viewed by another actor.
var on_view: KeyRef # Action
## Action triggered when this actor enters a map.
var on_map_entered: KeyRef # Action
## Action triggered when this actor exits a map.
var on_map_exited: KeyRef # Action
## Public resources visible on target focus plate when other actors view this actor.
var public: KeyRefArray # Resource
## Private resources visible only on own data plate.
var private: KeyRefArray # Resource
## Skills available to actor. Maximum 9 skills.
var skills: KeyRefArray # Skill
## Resource entities associated with this actor.
var resources: KeyRefArray # Resource
## Measure entities associated with this actor.
var measures: KeyRefArray # Measure
## Group entity for faction/team membership and outline color.
var group: KeyRef # Group
## Menu entity for custom interaction options.
var menu: KeyRef # Menu
## Trigger entities that monitor resource changes and execute actions.
var triggers: KeyRefArray # Trigger
## Timer entities that execute actions at intervals or after duration.
var timers: KeyRefArray # Timer
## Strategy entity for AI behavior control.
var strategy: KeyRef # Strategy
## Movement speed in pixels per second.
var speed: float
## Current facing direction in degrees (0-360). Default north (0).
var bearing: int = 0

func _ready() -> void:
	tag(Group.ACTOR_ENTITY)
