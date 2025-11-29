extends Node

## Global queue autoload. 
class Item extends Object:
	var comment: String
	var start: float
	var expiry: float = -1.0
	var condition: Callable = func(): return true
	var task: Callable
	var target: Node
	var _target_is_set: bool = false
	var retry_count: int = 0
	
	class Builder extends Object:
		var obj: Item = Item.new()
		var _expire_time_input: float = 0
		
		func target(value: Node) -> Builder:
			obj._target_is_set = true
			obj.target = value
			return self
		
		func comment(value: String) -> Builder:
			obj.comment = value
			return self

		func expiry(seconds: float) -> Builder:
			_expire_time_input = seconds
			return self
		
		func condition(value: Callable) -> Builder:
			obj.condition = value
			return self
			
		func task(value: Callable) -> Builder:
			obj.task = value
			return self
					
		func build() -> Item:
			obj.start = Time.get_unix_time_from_system()
			obj.expiry = obj.start + _expire_time_input
			return obj
			
	func is_expired() -> bool:
		if expiry < 0:
			return false
		return Time.get_unix_time_from_system() < expiry

	static func builder() -> Item.Builder:
		return Item.Builder.new()

var items: Array[Item] = []

func _ready():
	Logger.debug("Queue autoload initialized")

func enqueue(item: Item) -> void:
	Logger.trace("Enqueuing task: %s" % item.comment)
	items.append(item)

func _target_is_now_null(item: Item) -> bool:
	if item._target_is_set:
		return item.target == null 
	return false
	
func _call_condition_safe(item: Item) -> bool:
	if item.condition == null: return true
	if item.condition.is_valid():
		return item.condition.call()
	return true
		
func _call_task_safe(item: Item) -> void:
	if item.task == null: return
	if item.task.is_valid():
		item.task.call()

func _process(_delta: float) -> void:
	if items.size() > 0:
		var current_item = items[0]
		if current_item.is_expired(): 
			Logger.trace("Removing expired task: %s" % current_item.comment)
			items.pop_at(0)
		elif _target_is_now_null(current_item):
			Logger.trace("Removing task with null target: %s" % current_item.comment)
			items.pop_at(0)
		elif _call_condition_safe(current_item):
			Logger.trace("Executing task: %s" % current_item.comment)
			_call_task_safe(current_item)
			items.pop_at(0)
		else:
			current_item.retry_count += 1
			if current_item.retry_count > 10:
				Logger.warn("Task stuck in queue (retried %d times): %s" % [current_item.retry_count, current_item.comment])
				# Reset counter to avoid spam, but keep trying
				current_item.retry_count = 0
			items.append(items.pop_at(0))
