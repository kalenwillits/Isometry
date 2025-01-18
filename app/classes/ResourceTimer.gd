extends Timer
class_name ResourceTimer

var _tick_count: int = 0
var _tick_total_result: int
var action: Callable
var tick_total_expression: String
var tick_interval_expression: String

class Builder extends Object:
	var this: ResourceTimer = ResourceTimer.new()
	
	func total(value: String) -> Builder:
		this.tick_total_expression = value
		return self
	
	func interval(value: String) -> Builder:
		this.tick_interval_expression = value
		return self
		
	func action(value: Callable) -> Builder:
		this.action = value
		return self
	
	func build() -> ResourceTimer:
		return this
		
static func builder() -> Builder:
	return Builder.new()
	
func _ready() -> void:
	autostart = true
	add_to_group(Group.RESOURCE_TIMER)
	timeout.connect(_on_timeout)
	calculate_tick_total_count()
	
func _on_timeout() -> void:
	action.call()
	calculate_next_tick()
	
func calculate_next_tick() -> void:
	var caller: Actor = get_parent()
	var target: Actor = Optional.of(get_parent())\
		.map(func(actor): actor.target)\
		.or_else(get_parent())
	wait_time = Dice.builder()\
		.scene_tree(get_tree())\
		.caller(caller.name)\
		.target(target.name)\
		.expression(tick_interval_expression)\
		.build()\
	.evaluate()
	increment_tick_count()
	use_expiration()
	
func calculate_tick_total_count() -> void:
	_tick_total_result = Dice.builder()\
		.scene_tree(get_tree())\
		.caller(get_parent().name)\
		.target(get_parent().name)\
		.expression(tick_interval_expression)\
		.build()\
	.evaluate()
	
func increment_tick_count() -> void:
	_tick_count += 1

func use_expiration() -> void:
	if _tick_total_result == 0: return
	if _tick_count >= _tick_total_result: queue_free()
	
func get_tick_count() -> int:
	return _tick_count
