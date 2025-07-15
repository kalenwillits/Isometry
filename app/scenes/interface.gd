extends Node

func _ready() -> void:
	add_to_group(Group.INTEFACE)
	
func _process(_delta: float) -> void:
	update_primary_actor_info()
		
func update_primary_actor_info() -> void:
	if $DebugView.visible:
		var primary_actor: Actor = Finder.get_primary_actor()
		if primary_actor:
			var actor_ent: Entity = Repo.query([primary_actor.actor]).pop_front()
			set_display_name(primary_actor.display_name)
			set_position(str(primary_actor.position))
			set_origin(str(primary_actor.origin))
			set_destination(str(primary_actor.destination))
			for n in range(1, 10):
				var action_name: String = "action_%d" % n
				if actor_ent.get(action_name): 
					$DebugView/VBox/HBox/VBoxLeft/VBoxBot.get_node("ActionLabel%s" % n).set_text("%s: %s" % [n, actor_ent.get(action_name).key()])	

func set_display_name(value: String) -> void:
	$DebugView/VBox/HBox/VBoxLeft/VBoxTop/DisplayNameLabel.set_text("DISPLAY NAME: %s" % value)
	
func set_position(value: String) -> void:
	$DebugView/VBox/HBox/VBoxLeft/VBoxTop/LocationLabel.set_text("POSITION: %s" % value)
	
func set_origin(value: String) -> void:
	$DebugView/VBox/HBox/VBoxLeft/VBoxTop/OriginLabel.set_text("ORIGIN: %s" % value)
	
func set_destination(value: String) -> void:
	$DebugView/VBox/HBox/VBoxLeft/VBoxTop/DestinationLabel.set_text("DESTINATION: %s" % value)
