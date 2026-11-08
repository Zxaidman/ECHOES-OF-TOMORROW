class_name PopulationSimulation
extends RefCounted
## Deterministic named-NPC and aggregate population state.

const BACKGROUND_RESIDENTS: int = 20
const STAT_MAX: int = 100
var _npcs: Dictionary = {}
var _relationships: Dictionary = {}
var _background_residents: int = BACKGROUND_RESIDENTS
var _last_tick_minute: int = -1
var _daily_food_shortfalls: int = 0

func _init() -> void:
	var templates: Array[Dictionary] = [
		{"id":"mara","name":"Mara","role":"Village healer","age":34,"skills":{"medicine":72,"farming":12,"crafting":8}},
		{"id":"edric","name":"Edric","role":"Master carpenter","age":46,"skills":{"crafting":78,"farming":18,"medicine":5}},
		{"id":"elin","name":"Elin","role":"Farmer and seed keeper","age":29,"skills":{"farming":82,"crafting":16,"medicine":10}},
		{"id":"tomas","name":"Tomas","role":"Blacksmith apprentice","age":19,"skills":{"crafting":48,"farming":14,"medicine":4}},
		{"id":"aldwin","name":"Aldwin","role":"Village reeve","age":52,"skills":{"leadership":76,"farming":20,"crafting":12}}
	]
	for item: Dictionary in templates:
		_npcs[item.id] = {"id":item.id,"name":item.name,"role":item.role,"age":item.age,"skills":item.skills.duplicate(true),"health":100,"needs":{"hunger":25,"rest":20,"social":30},"goal":"work","activity":"working"}
	for source: String in _npcs:
		for target: String in _npcs:
			if source != target:
				_relationships[_key(source,target)] = {"trust":50,"cooperation":50,"conflict":0}

func get_population_count() -> int:
	return _npcs.size() + _background_residents

func get_npc_count() -> int:
	return _npcs.size()

func get_npc(npc_id: String) -> Dictionary:
	return _npcs.get(npc_id, {}).duplicate(true)

func get_npc_ids() -> Array[String]:
	var result: Array[String] = []
	for npc_id: String in _npcs:
		result.append(npc_id)
	result.sort()
	return result

func get_activity_at(npc_id: String, minute_of_day: int) -> String:
	if not _npcs.has(npc_id):
		return ""
	var hour: int = int(posmod(minute_of_day, 1440) / 60)
	if hour >= 22 or hour < 6:
		return "sleeping"
	if hour == 6 or hour == 12 or hour == 18:
		return "eating"
	if hour >= 7 and hour < 17:
		return "working"
	if hour >= 19 and hour < 22:
		return "socializing"
	return "resting"

func tick_hour(minute: int, ledger: ResourceLedger) -> Dictionary:
	if minute < 0 or minute % 60 != 0 or minute <= _last_tick_minute:
		return {"ok":false,"error":"Population tick must be a new hour boundary"}
	var hour: int = int(posmod(minute,1440) / 60)
	for npc_id: String in get_npc_ids():
		var npc: Dictionary = _npcs[npc_id]
		var needs: Dictionary = npc.needs
		var activity: String = get_activity_at(npc_id, minute)
		needs.hunger = mini(STAT_MAX, int(needs.hunger) + 5)
		needs.rest = maxi(0, int(needs.rest) - 12) if activity == "sleeping" else mini(STAT_MAX, int(needs.rest) + 4)
		needs.social = maxi(0, int(needs.social) - 18) if activity == "socializing" else mini(STAT_MAX, int(needs.social) + 3)
		if int(needs.hunger) >= 90:
			npc.health = maxi(0, int(npc.health) - 2)
		elif int(needs.hunger) <= 45:
			npc.health = mini(STAT_MAX, int(npc.health) + 1)
		npc.activity = activity
		npc.goal = _choose_goal(needs)
		_npcs[npc_id] = npc
	_last_tick_minute = minute
	if hour != 9:
		return {"ok":true,"food_consumed":0,"food_shortfall":false}
	var cost: int = int(ceil(float(get_population_count()) / 2.0))
	var payment: Dictionary = ledger.apply_transaction({"food":-cost})
	if payment.ok:
		return {"ok":true,"food_consumed":cost,"food_shortfall":false}
	_daily_food_shortfalls += 1
	for npc_id: String in _npcs:
		var npc: Dictionary = _npcs[npc_id]
		npc.health = maxi(0, int(npc.health) - 5)
		_npcs[npc_id] = npc
	return {"ok":true,"food_consumed":0,"food_shortfall":true,"error":str(payment.error)}

func set_relationship(source: String, target: String, values: Dictionary) -> Dictionary:
	if source == target or not _npcs.has(source) or not _npcs.has(target):
		return {"ok":false,"error":"Relationship requires two distinct known NPCs"}
	var next: Dictionary = _relationships[_key(source,target)].duplicate(true)
	for dimension: Variant in values:
		if not ["trust","cooperation","conflict"].has(dimension):
			return {"ok":false,"error":"Unknown relationship dimension"}
		var value: Variant = values[dimension]
		if typeof(value) != TYPE_INT or int(value) < 0 or int(value) > STAT_MAX:
			return {"ok":false,"error":"Relationship values must be integers from 0 to 100"}
		next[dimension] = value
	_relationships[_key(source,target)] = next
	return {"ok":true,"relationship":next.duplicate(true)}

func get_relationship(source: String, target: String) -> Dictionary:
	return _relationships.get(_key(source,target), {}).duplicate(true)

func get_overview_text() -> String:
	var healthy: int = 0
	var hungry: int = 0
	for npc_id: String in _npcs:
		var npc: Dictionary = _npcs[npc_id]
		if int(npc.health) >= 70:
			healthy += 1
		if int(npc.needs.hunger) >= 70:
			hungry += 1
	return "POPULATION  %d residents  ·  %d named  ·  %d healthy  ·  %d hungry  ·  %d daily food shortfalls" % [get_population_count(),_npcs.size(),healthy,hungry,_daily_food_shortfalls]

func create_save_state() -> Dictionary:
	return {"background_residents":_background_residents,"npcs":_npcs.duplicate(true),"relationships":_relationships.duplicate(true),"last_tick_minute":_last_tick_minute,"daily_food_shortfalls":_daily_food_shortfalls}

func restore_save_state(state: Dictionary) -> Dictionary:
	if typeof(state.get("background_residents",null)) != TYPE_INT or int(state.background_residents) < 0:
		return {"ok":false,"error":"Invalid background resident count"}
	if not state.get("npcs",null) is Dictionary or not state.get("relationships",null) is Dictionary:
		return {"ok":false,"error":"Population save is missing NPC or relationship state"}
	if typeof(state.get("last_tick_minute",null)) != TYPE_INT or typeof(state.get("daily_food_shortfalls",null)) != TYPE_INT:
		return {"ok":false,"error":"Population save is missing tick metadata"}
	var npcs: Dictionary = state.npcs.duplicate(true)
	for npc_id: String in npcs:
		var npc: Variant = npcs[npc_id]
		if not npc is Dictionary or str(npc.get("id","")) != npc_id or not npc.get("needs",null) is Dictionary or not npc.get("skills",null) is Dictionary:
			return {"ok":false,"error":"Population save contains an invalid NPC"}
		for stat: String in ["health","age"]:
			if typeof(npc.get(stat,null)) != TYPE_INT or int(npc[stat]) < 0 or (stat == "health" and int(npc[stat]) > STAT_MAX):
				return {"ok":false,"error":"Population save contains an invalid NPC stat"}
		for need: String in ["hunger","rest","social"]:
			if typeof(npc.needs.get(need,null)) != TYPE_INT or int(npc.needs[need]) < 0 or int(npc.needs[need]) > STAT_MAX:
				return {"ok":false,"error":"Population save contains an invalid need"}
	_background_residents = int(state.background_residents)
	_npcs = npcs
	_relationships = state.relationships.duplicate(true)
	_last_tick_minute = int(state.last_tick_minute)
	_daily_food_shortfalls = int(state.daily_food_shortfalls)
	return {"ok":true}

func _choose_goal(needs: Dictionary) -> String:
	if int(needs.hunger) >= 70:
		return "find_food"
	if int(needs.rest) >= 75:
		return "rest"
	if int(needs.social) >= 80:
		return "seek_company"
	return "work"

func _key(source: String, target: String) -> String:
	return source + ">" + target
