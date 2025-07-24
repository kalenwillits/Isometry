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
var network: Network.Mode = cliargs.get("network", "0").to_int()
var campaign: String = ""
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
	for key in expiry.keys():
		if expiry[key] < 0:
			continue
		if expiry[key] < now:
			expiry.erase(key)
			packs.erase(key)

func pack(pack: Pack) -> Variant:
	var object: Variant = Optional.of_nullable(packs.get(pack.key)).or_else(pack.ref.call())
	packs[pack.key] = object
	return object
	
func unpack(key: String) -> Variant:
	var object: Variant = packs.get(key)
	packs.erase(key)
	return object

func pack_actor(peer_id: int, pack: Dictionary) -> void:
	packed_actors[peer_id] = pack

func unpack_actor(peer_id: int) -> Dictionary:
	var result = packed_actors.get(peer_id, {}).duplicate()
	packed_actors.erase(peer_id)
	return result

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
