extends Node

# System
var cliargs: Dictionary = _parse_command_line_args()

# Launcher fields
var uri: String = "localhost"
var port: int = 5000
var delay: int = 0
var username: String
var password: String

# Runtime storage
var network: Network.Mode = _parse_network_mode(cliargs.get("network", "0")) as Network.Mode
var campaign: String = ""
var campaign_checksum: String = ""
var campaign_mismatch_error: bool = false
var dir: String = ""
var textures: Dictionary  # Storage of already loaded textures
var camera_zoom: int = 3
# TODO - swap this over to the other cache system
var packed_actors: Dictionary = {}  # used to store actors server-side that are being transistioned

var packs: Dictionary = {} # Cached objects
var expiry: Dictionary = {}

class Pack extends Object:
	var key: String
	var ref: Callable
	var expiry: float = -1

	class Builder extends Object:
		var this: Pack = Pack.new()
		
		func key(value: String) -> Builder:
			this.key = value
			return self
			
		func ref(value: Callable) -> Builder:
			this.ref = value
			return self
			
		func expiry(value: float) -> Builder:
			this.expiry = value
			return self
		
		func build() -> Pack:
			this.expiry = this.expiry + Time.get_unix_time_from_system()
			return this

	static func builder() -> Pack.Builder:
		return Builder.new()

func _ready() -> void:
	pass

func pack_audio() -> void:
	## Pre-packs ALL audio files into the cache.
	for sound_ent in Repo.query([Group.SOUND_ENTITY]):
		Cache.pack(
			Cache.Pack.builder()
				.key(sound_ent.source)
				.ref(func(): return AssetLoader.builder().archive(Cache.campaign).loop(sound_ent.loop).key(sound_ent.source).type(AssetLoader.derive_type_from_path(sound_ent.source).get_value()).build().pull())
				.build()
		)

		
func _handle_expiry() -> void:
	var now: float = Time.get_unix_time_from_system()
	var keys: Array = expiry.keys().duplicate()
	var expired_count = 0
	for key in keys:
		if expiry[key] < 0:
			continue
		if expiry[key] < now:
			expiry.erase(key)
			packs.erase(key)
			expired_count += 1
	if expired_count > 0:
		Logger.debug("Cache: Expired %d entries" % expired_count)

func pack(pack_data: Pack) -> Variant:
	var was_cached = packs.has(pack_data.key)
	var object: Variant = Optional.of_nullable(packs.get(pack_data.key)).or_else(pack_data.ref.call())
	packs[pack_data.key] = object

	if was_cached:
		Logger.trace("Cache hit: key=%s" % pack_data.key)
	else:
		Logger.debug("Cache pack: key=%s expiry=%s" % [pack_data.key, "never" if pack_data.expiry < 0 else str(pack_data.expiry - Time.get_unix_time_from_system()) + "s"])

	return object
	
func unpack(key: String) -> Variant:
	var object: Variant = packs.get(key)
	if object == null:
		Logger.trace("Cache miss on unpack: key=%s" % key)
	else:
		Logger.debug("Cache unpack: key=%s" % key)
	packs.erase(key)
	return object

func pack_actor(peer_id: int, pack_data: Dictionary) -> void:
	Logger.debug("Cache: Packing actor data for peer_id=%d" % peer_id)
	packed_actors[peer_id] = pack_data

func unpack_actor(peer_id: int) -> Dictionary:
	var result = packed_actors.get(peer_id, {}).duplicate()
	if result.is_empty():
		Logger.warn("Cache: No packed actor data found for peer_id=%d" % peer_id)
	else:
		Logger.debug("Cache: Unpacking actor data for peer_id=%d" % peer_id)
	packed_actors.erase(peer_id)
	return result

# Parse network mode from CLI argument (supports int, string names, and abbreviations)
# Examples: "0", "1", "HOST", "host", "h", "Server", "s", "client", "c"
# Returns Network.Mode enum value, defaults to NONE if invalid
func _parse_network_mode(input: String) -> int:
	var trimmed = input.strip_edges().strip_escapes()

	# Try parsing as integer first (backward compatibility)
	if trimmed.is_valid_int():
		var value = trimmed.to_int()
		# Validate range [0-3]
		if value >= 0 and value <= 3:
			return value
		else:
			push_warning("Cache._parse_network_mode: Integer value %d out of range [0-3], using NONE" % value)
			return 0  # Network.Mode.NONE

	# Try parsing as string name (case-insensitive)
	var upper_input = trimmed.to_upper()

	# Support full names and abbreviations
	if upper_input == "NONE" or upper_input == "N":
		return 0  # Network.Mode.NONE
	elif upper_input == "HOST" or upper_input == "H":
		return 1  # Network.Mode.HOST
	elif upper_input == "SERVER" or upper_input == "S":
		return 2  # Network.Mode.SERVER
	elif upper_input == "CLIENT" or upper_input == "C":
		return 3  # Network.Mode.CLIENT
	else:
		push_warning("Cache._parse_network_mode: Invalid mode name '%s', using NONE" % trimmed)
		return 0  # Network.Mode.NONE

func _parse_command_line_args() -> Dictionary:
	var args = OS.get_cmdline_args()  # Get the command line arguments
	var result = Dictionary()

	for i in range(args.size()):
		var arg = args[i]
		
		if arg.begins_with("--"):  # Handle long-form arguments
			var key = arg.substr(2)  # Remove the "--"
			var value = ""
			# Check for equals sign
			if key.find("=") != -1:
				var parts = key.split("=")
				key = parts[0]
				value = parts[1]
			elif i + 1 < args.size() and not args[i + 1].begins_with("--"):
				value = args[i + 1]
				# Skip the next argument since it’s the value for the current key
				i += 1

			result[key] = value

		elif arg.begins_with("-"):  # Handle single dash arguments
			var key = arg.substr(1)
			result[key] = true  # Treat single dash flags as boolean

	return result
