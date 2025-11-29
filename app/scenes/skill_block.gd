extends Widget

@export var key: String  # Skill entity key

func _ready() -> void:
	super._ready()  # Call Widget's _ready to set up theming hooks

	var entity: Entity = Repo.select(key)
	if entity == null:
		push_warning("SkillBlock: Could not find skill entity with key: %s" % key)
		return

	# Load and set icon
	var icon_texture: ImageTexture = AssetLoader.builder()\
		.key(entity.icon)\
		.type(AssetLoader.Type.IMAGE)\
		.archive(Cache.campaign)\
		.build()\
		.pull()
	$Button/Content/Icon.set_texture(icon_texture)

	# Set skill name
	$Button/Content/TextContainer/NameLabel.set_text(entity.name_)

	# Set skill description with resource/measure injection
	if entity.get("description") and entity.description != "":
		# Get the primary actor for injection
		var primary_actor = Finder.get_primary_actor()
		var caller_name = str(primary_actor.name) if primary_actor else ""

		# Process text through Dice engine for resource/measure injection
		var processed_desc = process_description(entity.description, caller_name, caller_name)

		$Button/Content/TextContainer/DescriptionLabel.clear()
		$Button/Content/TextContainer/DescriptionLabel.append_text(processed_desc)
	else:
		$Button/Content/TextContainer/DescriptionLabel.clear()

	# Connect button press
	$Button.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	# Future: Could open skill details or trigger skill usage
	pass

func process_description(text: String, caller: String, target: String) -> String:
	"""
	Process skill description text with resource/measure injection.
	Supports {{$variable}} for caller and {{@variable}} for target.
	Also supports BBCode formatting.
	"""
	var processed = text
	var regex = RegEx.new()
	regex.compile("\\{\\{([^}]+)\\}\\}")

	var matches = regex.search_all(processed)
	if matches == null or matches.size() == 0:
		return processed

	# Process matches in reverse order to avoid offset issues
	for i in range(matches.size() - 1, -1, -1):
		var match_ = matches[i]
		var expression = match_.get_string(1).strip_edges()

		# Use Dice engine to evaluate and inject actor values
		var dice = Dice.builder()\
			.caller(caller)\
			.target(target)\
			.expression(expression)\
			.build()

		# Get processed expression with injected values
		var result = dice.get_processed_expression()
		processed = processed.substr(0, match_.get_start()) + result + processed.substr(match_.get_end())

	return processed

func set_key(value: String) -> void:
	key = value
