extends PhysicsRayQueryParameters2D
class_name LineOfSightQueryParameters

class Builder:
	var this: LineOfSightQueryParameters = LineOfSightQueryParameters.new()
	
	func from(value: Vector2) -> Builder:
		this.from = value
		return self
	
	func to(value: Vector2) -> Builder:
		this.to = value
		return self
		
	func build() -> LineOfSightQueryParameters:
		this.collision_mask = Layer.WALL
		this.hit_from_inside = true
		return this
		
	
static func builder() -> Builder:
	return Builder.new()
