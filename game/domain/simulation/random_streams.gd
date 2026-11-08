class_name RandomStreams
extends RefCounted
## Independent deterministic RNG streams persisted with campaign state.
const WORLD_SALT: int = 439041101
const ECONOMY_SALT: int = 826366246
const NPC_SALT: int = 1229801703
var _world: RandomNumberGenerator = RandomNumberGenerator.new()
var _economy: RandomNumberGenerator = RandomNumberGenerator.new()
var _npc: RandomNumberGenerator = RandomNumberGenerator.new()

func _init(master_seed: int = 1) -> void:
	seed_streams(master_seed)

func seed_streams(master_seed: int) -> void:
	_world.seed = master_seed ^ WORLD_SALT
	_economy.seed = master_seed ^ ECONOMY_SALT
	_npc.seed = master_seed ^ NPC_SALT

func world_randi_range(from_value: int, to_value: int) -> int:
	return _world.randi_range(from_value, to_value)

func economy_randi_range(from_value: int, to_value: int) -> int:
	return _economy.randi_range(from_value, to_value)

func npc_randi_range(from_value: int, to_value: int) -> int:
	return _npc.randi_range(from_value, to_value)

func to_dictionary() -> Dictionary:
	return {"world": _world.state, "economy": _economy.state, "npc": _npc.state}

func restore(states: Dictionary) -> Dictionary:
	for stream_name: String in ["world", "economy", "npc"]:
		if not states.has(stream_name) or not states[stream_name] is int:
			return {"ok": false, "error": "Missing or invalid RNG state: %s" % stream_name}
	_world.state = int(states["world"])
	_economy.state = int(states["economy"])
	_npc.state = int(states["npc"])
	return {"ok": true}
