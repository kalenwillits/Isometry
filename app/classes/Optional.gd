## Based on: https://docs.oracle.com/javase/8/docs/api/java/util/Optional.html
extends Object
class_name Optional

# Store the value of type T, if present.
var _value: Variant = null

# Constructor that accepts an optional value
func _init(value: Variant = null):
	_value = value

# Static method to create an empty Optional (no value present)
static func empty() -> Optional:
	return Optional.new()

# Static method to create an Optional with a non-null value
static func of(value: Variant) -> Optional:
	assert(value != null, "Cannot create Optional with null value.")
	return Optional.new(value)

# Static method to create an Optional, which may or may not have a value
static func of_nullable(value: Variant) -> Optional:
	return Optional.new(value)

# Method to check if the value is present
func is_present() -> bool:
	return _value != null

# Method to return the value, or throw an error if not present
func get_value() -> Variant:
	if not is_present():
		push_error("No value present in Optional.")
		return null
	return _value

# Method to execute a callback if the value is present
func if_present(callback: Callable) -> void:
	if is_present():
		callback.call([_value])

# Method to filter the value based on a predicate (callback)
func filter(predicate: Callable) -> Optional:
	if is_present() and predicate.call([_value]):
		return self
	return Optional.empty()

# Method to map the value to another Optional using a mapping function
func map(mapper: Callable) -> Optional:
	if is_present():
		var mapped_value = mapper.call(_value)
		if mapped_value != null:
			return Optional.of_nullable(mapped_value)
	return Optional.empty()

# Method to flatMap the value to another Optional using a mapping function
func flat_map(mapper: Callable) -> Optional:
	if is_present():
		var result = mapper.call([_value])
		if result is Optional:
			return result
	return Optional.empty()

# Method to return the value if present, or a default if not
func or_else(other: Variant) -> Variant:
	return _value if is_present() else other

# Method to return the value if present, or invoke a supplier to get a default
func or_else_get(supplier: Callable) -> Variant:
	return _value if is_present() else supplier.call([])
