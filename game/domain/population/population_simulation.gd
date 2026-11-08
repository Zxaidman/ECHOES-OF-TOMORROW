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
var _memories: Dictionary = {}
const MAX_MEMORIES_PER_NPC: int = 50
const MEMORY_DECAY_INTERVAL_MINUTES: int = 43200

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
		_memories[item.id] = []
	for source: String in _npcs:
		for target: String in _npcs:
			if source != target:
				_relationships[_key(source,target)] = {"trust":50,"cooperation":50,"conflict":0}

func get_population_count() -> int:
	return _npcs.size() + _background_residents

func get_npc_count() -> int:
	return _npcs.size()

func get_best_skill(skill_id: String) -> int:
	var best: int = 0
	for npc_id: String in _npcs:
		var skills: Dictionary = _npcs[npc_id].get("skills", {})
		best = maxi(best, int(skills.get(skill_id, 0)))
	return best

func get_npc(npc_id: String) -> Dictionary:
	return _npcs.get(npc_id, {}).duplicate(true)

func record_memory(npc_id: String, memory: Dictionary) -> Dictionary:
	if not _npcs.has(npc_id):
		return {"ok":false,"error":"Cannot record memory for an unknown NPC"}
	var validation: Dictionary = _validate_memory(memory)
	if not validation.ok:
		return validation
	var memories: Array = _memories.get(npc_id, []).duplicate(true)
	for index: int in range(memories.size() - 1, -1, -1):
		if _effective_importance(memories[index], int(memory.timestamp_minute)) <= 0:
			memories.remove_at(index)
	for existing: Dictionary in memories:
		if str(existing.id) == str(memory.id):
			return {"ok":false,"error":"Memory ID already exists for this NPC"}
	memories.append(memory.duplicate(true))
	while memories.size() > MAX_MEMORIES_PER_NPC:
		var remove_index: int = 0
		for index: int in range(1, memories.size()):
			var candidate: Dictionary = memories[index]
			var selected: Dictionary = memories[remove_index]
			var candidate_score: int = _effective_importance(candidate, int(memory.timestamp_minute))
			var selected_score: int = _effective_importance(selected, int(memory.timestamp_minute))
			if candidate_score < selected_score or (candidate_score == selected_score and int(candidate.timestamp_minute) < int(selected.timestamp_minute)) or (candidate_score == selected_score and int(candidate.timestamp_minute) == int(selected.timestamp_minute) and str(candidate.id) > str(selected.id)):
				remove_index = index
		memories.remove_at(remove_index)
	_memories[npc_id] = memories
	return {"ok":true,"memory_count":memories.size()}

func get_memory_count(npc_id: String = "") -> int:
	if not npc_id.is_empty():
		return _memories.get(npc_id, []).size()
	var total: int = 0
	for records: Array in _memories.values():
		total += records.size()
	return total

func get_memories(npc_id: String) -> Array:
	return _memories.get(npc_id, []).duplicate(true)

func retrieve_memories(npc_id: String, topic_tags: Array = [], participant_ids: Array = [], current_minute: int = 0, limit: int = 5) -> Array:
	if not _npcs.has(npc_id) or current_minute < 0 or limit < 1:
		return []
	var bounded_limit: int = mini(limit, 5)
	var ranked: Array[Dictionary] = []
	for memory: Dictionary in _memories.get(npc_id, []):
		var effective_importance: int = _effective_importance(memory, current_minute)
		if effective_importance <= 0:
			continue
		var topic_matches: int = 0
		for tag: Variant in topic_tags:
			if tag is String and memory.tags.has(tag):
				topic_matches += 1
		var participant_matches: int = 0
		for participant: Variant in participant_ids:
			if participant is String and memory.participants.has(participant):
				participant_matches += 1
		var age_days: int = int((current_minute - int(memory.timestamp_minute)) / 1440)
		var recency_bonus: int = maxi(0, 30 - int(age_days / 30))
		var relevance: int = effective_importance * 10 + (25 if topic_matches > 0 else 0) + (15 if participant_matches > 0 else 0) + recency_bonus
		var item: Dictionary = memory.duplicate(true)
		item["relevance_score"] = relevance
		ranked.append(item)
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.relevance_score) != int(b.relevance_score):
			return int(a.relevance_score) > int(b.relevance_score)
		if int(a.timestamp_minute) != int(b.timestamp_minute):
			return int(a.timestamp_minute) > int(b.timestamp_minute)
		return str(a.id) < str(b.id)
	)
	var result: Array = []
	for index: int in range(mini(bounded_limit, ranked.size())):
		result.append(ranked[index])
	return result

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
	return {"background_residents":_background_residents,"npcs":_npcs.duplicate(true),"relationships":_relationships.duplicate(true),"last_tick_minute":_last_tick_minute,"daily_food_shortfalls":_daily_food_shortfalls,"memories":_memories.duplicate(true)}

func restore_save_state(state: Dictionary) -> Dictionary:
	if not _is_integral_number(state.get("background_residents",null)) or int(state.background_residents) < 0:
		return {"ok":false,"error":"Invalid background resident count"}
	if not state.get("npcs",null) is Dictionary or not state.get("relationships",null) is Dictionary:
		return {"ok":false,"error":"Population save is missing NPC or relationship state"}
	if not _is_integral_number(state.get("last_tick_minute",null)) or not _is_integral_number(state.get("daily_food_shortfalls",null)):
		return {"ok":false,"error":"Population save is missing tick metadata"}
	var npcs: Dictionary = state.npcs.duplicate(true)
	for npc_id: String in npcs:
		var npc: Variant = npcs[npc_id]
		if not npc is Dictionary or str(npc.get("id","")) != npc_id or not npc.get("needs",null) is Dictionary or not npc.get("skills",null) is Dictionary:
			return {"ok":false,"error":"Population save contains an invalid NPC"}
		for stat: String in ["health","age"]:
			if not _is_integral_number(npc.get(stat,null)) or int(npc[stat]) < 0 or (stat == "health" and int(npc[stat]) > STAT_MAX):
				return {"ok":false,"error":"Population save contains an invalid NPC stat"}
		for need: String in ["hunger","rest","social"]:
			if not _is_integral_number(npc.needs.get(need,null)) or int(npc.needs[need]) < 0 or int(npc.needs[need]) > STAT_MAX:
				return {"ok":false,"error":"Population save contains an invalid need"}
	var restored_memories: Dictionary = {}
	for npc_id: String in npcs:
		restored_memories[npc_id] = []
	if state.has("memories"):
		if not state.memories is Dictionary:
			return {"ok":false,"error":"Population save contains invalid memory state"}
		for npc_id: Variant in state.memories:
			if not npc_id is String or not npcs.has(npc_id) or not state.memories[npc_id] is Array:
				return {"ok":false,"error":"Population save contains memories for an unknown NPC"}
			var seen_memory_ids: Dictionary = {}
			for memory: Variant in state.memories[npc_id]:
				var memory_validation: Dictionary = _validate_memory(memory)
				if not memory_validation.ok or seen_memory_ids.has(str(memory.get("id",""))):
					return {"ok":false,"error":"Population save contains an invalid or duplicate memory"}
				seen_memory_ids[str(memory.id)] = true
				restored_memories[npc_id].append(memory.duplicate(true))
			if restored_memories[npc_id].size() > MAX_MEMORIES_PER_NPC:
				return {"ok":false,"error":"Population save exceeds the per-NPC memory limit"}
	_background_residents = int(state.background_residents)
	_npcs = npcs
	_relationships = state.relationships.duplicate(true)
	_last_tick_minute = int(state.last_tick_minute)
	_daily_food_shortfalls = int(state.daily_food_shortfalls)
	_memories = restored_memories
	return {"ok":true}

func _validate_memory(memory: Variant) -> Dictionary:
	if not memory is Dictionary:
		return {"ok":false,"error":"Memory must be an object"}
	var required: Array[String] = ["id","event_id","timestamp_minute","summary","importance","source","confidence","participants","tags"]
	for field: String in required:
		if not memory.has(field):
			return {"ok":false,"error":"Memory is missing field: " + field}
	if not memory.id is String or str(memory.id).is_empty() or str(memory.id).length() > 64:
		return {"ok":false,"error":"Memory ID must be a non-empty string up to 64 characters"}
	if not memory.event_id is String or str(memory.event_id).length() > 64:
		return {"ok":false,"error":"Memory event ID must be a string up to 64 characters"}
	if not _is_integral_number(memory.timestamp_minute) or int(memory.timestamp_minute) < 0:
		return {"ok":false,"error":"Memory timestamp must be a non-negative integer"}
	if not memory.summary is String or str(memory.summary).strip_edges().is_empty() or str(memory.summary).length() > 240:
		return {"ok":false,"error":"Memory summary must contain 1 to 240 characters"}
	if not _is_integral_number(memory.importance) or int(memory.importance) < 1 or int(memory.importance) > STAT_MAX:
		return {"ok":false,"error":"Memory importance must be an integer from 1 to 100"}
	if not memory.source is String or not ["witnessed","hearsay"].has(memory.source):
		return {"ok":false,"error":"Memory source must be witnessed or hearsay"}
	if not _is_integral_number(memory.confidence) or int(memory.confidence) < 0 or int(memory.confidence) > STAT_MAX:
		return {"ok":false,"error":"Memory confidence must be an integer from 0 to 100"}
	if not memory.participants is Array or not memory.tags is Array or memory.participants.size() > 8 or memory.tags.size() > 8:
		return {"ok":false,"error":"Memory participants and tags must be bounded arrays"}
	for participant: Variant in memory.participants:
		if not participant is String or str(participant).is_empty() or str(participant).length() > 64:
			return {"ok":false,"error":"Memory participants must be non-empty string IDs"}
	for tag: Variant in memory.tags:
		if not tag is String or str(tag).is_empty() or str(tag).length() > 32:
			return {"ok":false,"error":"Memory tags must be non-empty strings up to 32 characters"}
	return {"ok":true}

func _effective_importance(memory: Dictionary, current_minute: int) -> int:
	var age: int = maxi(0, current_minute - int(memory.timestamp_minute))
	return maxi(0, int(memory.importance) - int(age / MEMORY_DECAY_INTERVAL_MINUTES))

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

static func _is_integral_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or (typeof(value) == TYPE_FLOAT and value == floor(value))
