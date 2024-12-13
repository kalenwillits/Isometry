extends Node
class_name Trigger

var _previous_value
var _value_ref: String
var _self_destruct: bool

signal on_fire
signal on_self_destruct

## Abstract trigger node
## Use this in parent node.
## 	Trigger.new().arm("value_name").action(build_hitbox).deploy(self)


static func new() -> Trigger:
	var new_trigger = Trigger.new()
	new_trigger.set_name("Trigger(Unarmmed)")
	return new_trigger

func arm(value_ref: String) -> Trigger:
	set_ref(value_ref)
	set_name("Trigger(%s)" % _value_ref)
	return self
	
func deploy(parent_ref: Node) -> void:
	parent_ref.add_child(self)
	
func action(lambda: Callable) -> Trigger:
	on_fire.connect(lambda)
	return self
	
func delay(seconds: float) -> Trigger:
	set_physics_process(false)
	var timer: Timer = Timer.new()
	timer.autostart = true
	timer.one_shot = true
	timer.wait_time = seconds
	timer.timeout.connect(func(): set_physics_process(true); timer.queue_free())
	self.add_child(timer)
	return self

func set_ref(value_ref: String) -> void:
	_value_ref = value_ref
	
func set_self_destruct(self_destruct: bool) -> void:
	_self_destruct = self_destruct
		
func _physics_process(_delta) -> void:
	var value = get_parent().get(_value_ref)
	if value != null and value != _previous_value:
		_previous_value = value
		on_fire.emit()
		if _self_destruct:
			on_self_destruct.emit()
			queue_free()
