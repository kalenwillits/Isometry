extends Node

## Global queue autoload. 
class Item extends Object:
	var comment: String
	var start: float
	var expiry: float = -1.0
	var condition: Callable = func(): return true
	var task: Callable
	
	class Builder extends Object:
		var obj: Item = Item.new()
		var _expire_time_input: float = 0
		
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

func enqueue(item: Item) -> void:
	items.append(item)

func _process(_delta: float) -> void:
	if items.size() > 0:
		if items[0].is_expired(): 
			items.pop_at(0)
		elif items[0].condition.call():
			items[0].task.call()
			items.pop_at(0)
		else:
			items.append(items.pop_at(0))
