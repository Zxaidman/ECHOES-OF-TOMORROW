class_name HistoricalTimeline
extends RefCounted
## Authored historical events, player choices and the original/altered campaign record.

const ContentCatalog = preload("res://game/infrastructure/content/content_catalog.gd")
const MAX_EVENTS: int = 1000
const MAX_CHOICES: int = 8
var _definitions: Dictionary = {}
var _records: Dictionary = {}

func initialize(start_minute: int) -> Dictionary:
	if start_minute < 0:
		return {"ok":false,"error":"Timeline start minute cannot be negative"}
	var loaded: Dictionary = ContentCatalog.load_collection("res://content/historical_events.json","events")
	if not loaded.ok:
		return loaded
	if loaded.items.size() > MAX_EVENTS:
		return {"ok":false,"error":"Historical event catalog exceeds its limit"}
	var definitions: Dictionary = {}
	for definition: Variant in loaded.items:
		var validation: Dictionary = _validate_definition(definition)
		if not validation.ok:
			return validation
		definitions[str(definition.id)] = definition.duplicate(true)
	for event_id: String in definitions:
		var definition: Dictionary = definitions[event_id]
		for choice: Dictionary in definition.choices:
			var follow_up: Dictionary = choice.get("follow_up",{})
			if not follow_up.is_empty() and (not definitions.has(str(follow_up.get("event_id",""))) or str(follow_up.event_id) == event_id):
				return {"ok":false,"error":"Historical event has an unknown or self-referencing follow-up"}
	_definitions = definitions
	_records.clear()
	for event_id: String in definitions:
		var scheduled_minute: int = int(definitions[event_id].scheduled_minute)
		var is_root: bool = scheduled_minute >= 0
		var status: String = "scheduled" if is_root and scheduled_minute >= start_minute else ("missed" if is_root else "dormant")
		_records[event_id] = {
			"id":event_id,
			"original_minute":scheduled_minute,
			"scheduled_minute":scheduled_minute,
			"triggered_minute":-1,
			"resolution_minute":-1,
			"status":status,
			"selected_choice_id":"",
			"changed":false
		}
	for event_id: String in definitions:
		var baseline_choice_id: String = str(definitions[event_id].baseline_choice_id)
		for choice: Dictionary in definitions[event_id].choices:
			if str(choice.id) == baseline_choice_id:
				var baseline_follow_up: Dictionary = choice.get("follow_up",{})
				if not baseline_follow_up.is_empty():
					var follow_id: String = str(baseline_follow_up.event_id)
					var expected_minute: int = int(_records[event_id].original_minute) + int(baseline_follow_up.delay_minutes)
					if int(_records[follow_id].original_minute) >= 0 and int(_records[follow_id].original_minute) != expected_minute:
						return {"ok":false,"error":"Historical event has conflicting original timeline dates"}
					var follow_record: Dictionary = _records[follow_id].duplicate(true)
					follow_record.original_minute = expected_minute
					_records[follow_id] = follow_record
	return {"ok":true,"scheduled_events":get_scheduled_events()}

func get_scheduled_events() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event_id: String in _records:
		var record: Dictionary = _records[event_id]
		if record.status == "scheduled":
			result.append({"event_id":event_id,"scheduled_minute":int(record.scheduled_minute)})
	result.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
		if int(a.scheduled_minute) != int(b.scheduled_minute):
			return int(a.scheduled_minute) < int(b.scheduled_minute)
		return str(a.event_id) < str(b.event_id)
	)
	return result

func trigger(event_id: String, minute: int) -> Dictionary:
	if not _records.has(event_id):
		return {"ok":false,"error":"Unknown historical event"}
	var record: Dictionary = _records[event_id].duplicate(true)
	if record.status != "scheduled" or minute < int(record.scheduled_minute):
		return {"ok":false,"error":"Historical event is not scheduled for this time"}
	record.status = "choice_pending"
	record.triggered_minute = minute
	_records[event_id] = record
	return {"ok":true,"event":get_event(event_id)}

func resolve(event_id: String, choice_id: String, minute: int, resources: ResourceLedger, population: PopulationSimulation) -> Dictionary:
	if not _records.has(event_id):
		return {"ok":false,"error":"Unknown historical event"}
	var record: Dictionary = _records[event_id].duplicate(true)
	if record.status != "choice_pending":
		return {"ok":false,"error":"Historical event is not awaiting a choice"}
	if minute < int(record.triggered_minute):
		return {"ok":false,"error":"Cannot resolve an event before it was triggered"}
	var definition: Dictionary = _definitions[event_id]
	var selected: Dictionary = {}
	for choice: Dictionary in definition.choices:
		if str(choice.id) == choice_id:
			selected = choice
			break
	if selected.is_empty():
		return {"ok":false,"error":"Unknown choice for historical event"}
	var requirements: Dictionary = selected.get("requirements",{})
	for resource_id: Variant in requirements:
		if not resource_id is String or not resources.has_resource(resource_id) or not _is_integral_number(requirements[resource_id]) or int(requirements[resource_id]) < 0:
			return {"ok":false,"error":"Historical choice contains an invalid resource requirement"}
		if resources.get_amount(resource_id) < int(requirements[resource_id]):
			return {"ok":false,"error":"Not enough %s for this choice" % str(resource_id)}
	var authored_deltas: Dictionary = selected.get("resource_deltas",{})
	var deltas: Dictionary = {}
	for resource_id: Variant in authored_deltas:
		if not resource_id is String or not resources.has_resource(resource_id) or not _is_integral_number(authored_deltas[resource_id]):
			return {"ok":false,"error":"Historical choice contains an invalid resource change"}
		deltas[str(resource_id)] = int(authored_deltas[resource_id])
	var relationship_updates: Array = selected.get("relationship_updates",[])
	var updated_pairs: Dictionary = {}
	for update: Variant in relationship_updates:
		if not update is Dictionary or population.get_npc(str(update.get("source",""))).is_empty() or population.get_npc(str(update.get("target",""))).is_empty() or str(update.get("source","")) == str(update.get("target","")):
			return {"ok":false,"error":"Historical choice contains an unknown NPC relationship"}
		var pair_id: String = str(update.source) + ">" + str(update.target)
		if updated_pairs.has(pair_id):
			return {"ok":false,"error":"Historical choice repeats a relationship update"}
		updated_pairs[pair_id] = true
		for dimension: String in ["trust","cooperation","conflict"]:
			if update.has(dimension) and (typeof(update[dimension]) != TYPE_INT or int(update[dimension]) < -100 or int(update[dimension]) > 100):
				return {"ok":false,"error":"Historical relationship change is outside its bounds"}
	var memory_specs: Array = selected.get("memories",[])
	for memory_spec: Variant in memory_specs:
		if not memory_spec is Dictionary or population.get_npc(str(memory_spec.get("npc_id",""))).is_empty():
			return {"ok":false,"error":"Historical choice contains a memory for an unknown NPC"}
		if not memory_spec.get("summary","") is String or str(memory_spec.summary).strip_edges().is_empty() or str(memory_spec.summary).length() > 240:
			return {"ok":false,"error":"Historical memory summary is invalid"}
		if not _is_integral_number(memory_spec.get("importance",null)) or int(memory_spec.importance) < 1 or int(memory_spec.importance) > 100:
			return {"ok":false,"error":"Historical memory importance is invalid"}
		if not ["witnessed","hearsay"].has(str(memory_spec.get("source","witnessed"))) or not _is_integral_number(memory_spec.get("confidence",100)) or int(memory_spec.get("confidence",100)) < 0 or int(memory_spec.get("confidence",100)) > 100:
			return {"ok":false,"error":"Historical memory provenance or confidence is invalid"}
		if not memory_spec.get("participants",[]) is Array or not memory_spec.get("tags",[]) is Array or memory_spec.get("participants",[]).size() > 8 or memory_spec.get("tags",[]).size() > 8:
			return {"ok":false,"error":"Historical memory participant/tag lists exceed their bounds"}
		var memory_id_check: String = "history-%s-%s-%s" % [event_id,choice_id,str(memory_spec.npc_id)]
		for existing_memory: Dictionary in population.get_memories(str(memory_spec.npc_id)):
			if str(existing_memory.id) == memory_id_check:
				return {"ok":false,"error":"Historical memory ID already exists"}
		for participant: Variant in memory_spec.get("participants",[]):
			if not participant is String or str(participant).is_empty() or str(participant).length() > 64 or population.get_npc(str(participant)).is_empty():
				return {"ok":false,"error":"Historical memory contains an invalid participant"}
		for tag: Variant in memory_spec.get("tags",[]):
			if not tag is String or str(tag).is_empty() or str(tag).length() > 32:
				return {"ok":false,"error":"Historical memory contains an invalid tag"}
	var follow_up: Dictionary = selected.get("follow_up",{})
	if not follow_up.is_empty():
		var follow_id: String = str(follow_up.get("event_id",""))
		if not _records.has(follow_id) or _records[follow_id].status != "dormant" or not _is_integral_number(follow_up.get("delay_minutes",null)) or int(follow_up.delay_minutes) < 1 or minute > 2147483647 - int(follow_up.delay_minutes):
			return {"ok":false,"error":"Historical follow-up is invalid or already activated"}
	var resource_result: Dictionary = {}
	if not deltas.is_empty():
		resource_result = resources.apply_transaction(deltas)
		if not resource_result.ok:
			return resource_result
	for update: Dictionary in relationship_updates:
		var current: Dictionary = population.get_relationship(str(update.source),str(update.target))
		var next: Dictionary = {}
		for dimension: String in ["trust","cooperation","conflict"]:
			if update.has(dimension):
				next[dimension] = clampi(int(current.get(dimension,50)) + int(update[dimension]),0,100)
		if not next.is_empty():
			var relationship_result: Dictionary = population.set_relationship(str(update.source),str(update.target),next)
			if not relationship_result.ok:
				return relationship_result
	for memory_spec: Dictionary in memory_specs:
		var memory_id: String = "history-%s-%s-%s" % [event_id,choice_id,str(memory_spec.npc_id)]
		var memory: Dictionary = {
			"id":memory_id,
			"event_id":event_id,
			"timestamp_minute":minute,
			"summary":str(memory_spec.summary),
			"importance":int(memory_spec.importance),
			"source":str(memory_spec.get("source","witnessed")),
			"confidence":int(memory_spec.get("confidence",100)),
			"participants":memory_spec.get("participants",[]).duplicate(true),
			"tags":memory_spec.get("tags",[]).duplicate(true)
		}
		var memory_result: Dictionary = population.record_memory(str(memory_spec.npc_id),memory)
		if not memory_result.ok:
			return memory_result
	record.selected_choice_id = choice_id
	record.resolution_minute = minute
	record.status = "preserved" if choice_id == str(definition.baseline_choice_id) else "altered"
	record.changed = choice_id != str(definition.baseline_choice_id)
	_records[event_id] = record
	var follow_up_result: Dictionary = {}
	if not follow_up.is_empty():
		var follow_id: String = str(follow_up.event_id)
		var follow_minute: int = minute + int(follow_up.delay_minutes)
		var follow_record: Dictionary = _records[follow_id].duplicate(true)
		follow_record.status = "scheduled"
		follow_record.scheduled_minute = follow_minute
		_records[follow_id] = follow_record
		follow_up_result = {"event_id":follow_id,"scheduled_minute":follow_minute}
	return {"ok":true,"event":get_event(event_id),"follow_up":follow_up_result}

func get_event(event_id: String) -> Dictionary:
	if not _definitions.has(event_id) or not _records.has(event_id):
		return {}
	var result: Dictionary = _definitions[event_id].duplicate(true)
	result["record"] = _records[event_id].duplicate(true)
	return result

func get_pending_events() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event_id: String in _records:
		if str(_records[event_id].status) == "choice_pending":
			result.append(get_event(event_id))
	result.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
		return int(a.record.triggered_minute) < int(b.record.triggered_minute)
	)
	return result

func get_timeline_entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event_id: String in _records:
		var definition: Dictionary = _definitions[event_id]
		var record: Dictionary = _records[event_id]
		var baseline_label: String = ""
		var selected_label: String = ""
		for choice: Dictionary in definition.choices:
			if str(choice.id) == str(definition.baseline_choice_id):
				baseline_label = str(choice.label)
			if str(choice.id) == str(record.selected_choice_id):
				selected_label = str(choice.label)
		result.append({
			"id":event_id,
			"title":str(definition.title),
			"baseline_choice_label":baseline_label,
			"selected_choice_label":selected_label,
			"original_minute":int(record.original_minute),
			"scheduled_minute":int(record.scheduled_minute),
			"resolution_minute":int(record.resolution_minute),
			"status":str(record.status),
			"baseline_choice_id":str(definition.baseline_choice_id),
			"selected_choice_id":str(record.selected_choice_id),
			"changed":bool(record.changed)
		})
	result.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
		var left: int = int(a.original_minute) if int(a.original_minute) >= 0 else 2147483647
		var right: int = int(b.original_minute) if int(b.original_minute) >= 0 else 2147483647
		if left != right:
			return left < right
		return str(a.id) < str(b.id)
	)
	return result

func create_save_state() -> Dictionary:
	return {"records":_records.duplicate(true)}

func restore_save_state(state: Dictionary) -> Dictionary:
	if not state.get("records",null) is Dictionary or state.records.size() != _definitions.size():
		return {"ok":false,"error":"Timeline save has an invalid record collection"}
	var restored: Dictionary = {}
	for event_id: String in _definitions:
		if not state.records.has(event_id) or not state.records[event_id] is Dictionary:
			return {"ok":false,"error":"Timeline save is missing event %s" % event_id}
		var record: Dictionary = state.records[event_id]
		for key: String in ["original_minute","scheduled_minute","triggered_minute","resolution_minute"]:
			if not _is_integral_number(record.get(key,null)):
				return {"ok":false,"error":"Timeline record has invalid minute metadata"}
		var status: String = str(record.get("status",""))
		if not ["scheduled","dormant","missed","choice_pending","preserved","altered"].has(status):
			return {"ok":false,"error":"Timeline record has an unknown status"}
		var selected: String = str(record.get("selected_choice_id",""))
		if not selected.is_empty():
			var found: bool = false
			for choice: Dictionary in _definitions[event_id].choices:
				if str(choice.id) == selected:
					found = true
			if not found:
				return {"ok":false,"error":"Timeline record contains an unknown selected choice"}
		if typeof(record.get("changed",null)) != TYPE_BOOL or bool(record.changed) != (status == "altered"):
			return {"ok":false,"error":"Timeline record contains an inconsistent changed flag"}
		if status in ["preserved","altered"] and (selected.is_empty() or int(record.resolution_minute) < int(record.triggered_minute)):
			return {"ok":false,"error":"Resolved timeline record is incomplete"}
		restored[event_id] = record.duplicate(true)
	_records = restored
	return {"ok":true}

func _validate_definition(definition: Variant) -> Dictionary:
	if not definition is Dictionary:
		return {"ok":false,"error":"Historical event must be an object"}
	for key: String in ["id","title","description","scheduled_minute","baseline_choice_id","choices"]:
		if not definition.has(key):
			return {"ok":false,"error":"Historical event is missing %s" % key}
	if not definition.title is String or str(definition.title).strip_edges().is_empty() or str(definition.title).length() > 100:
		return {"ok":false,"error":"Historical event title is invalid"}
	if not definition.description is String or str(definition.description).length() > 500:
		return {"ok":false,"error":"Historical event description is invalid"}
	if not _is_integral_number(definition.scheduled_minute) or int(definition.scheduled_minute) < -1:
		return {"ok":false,"error":"Historical event minute is invalid"}
	if not definition.choices is Array or definition.choices.is_empty() or definition.choices.size() > MAX_CHOICES:
		return {"ok":false,"error":"Historical event choices must be a bounded non-empty array"}
	var choice_ids: Dictionary = {}
	var has_baseline: bool = false
	for choice: Variant in definition.choices:
		if not choice is Dictionary or not choice.has("id") or not choice.id is String or str(choice.id).is_empty():
			return {"ok":false,"error":"Historical event choice has an invalid ID"}
		if choice_ids.has(choice.id):
			return {"ok":false,"error":"Historical event contains duplicate choice IDs"}
		choice_ids[choice.id] = true
		for key: String in ["label","description","requirements","resource_deltas","relationship_updates","memories"]:
			if not choice.has(key):
				return {"ok":false,"error":"Historical choice is missing %s" % key}
		if not choice.label is String or str(choice.label).is_empty() or str(choice.label).length() > 80 or not choice.description is String or str(choice.description).length() > 300:
			return {"ok":false,"error":"Historical choice text is invalid"}
		if not choice.requirements is Dictionary or not choice.resource_deltas is Dictionary or not choice.relationship_updates is Array or not choice.memories is Array or choice.relationship_updates.size() > 8 or choice.memories.size() > 8:
			return {"ok":false,"error":"Historical choice effects have invalid types or exceed their bounds"}
		for resource_id: Variant in choice.requirements:
			if not resource_id is String or not _is_integral_number(choice.requirements[resource_id]) or int(choice.requirements[resource_id]) < 0:
				return {"ok":false,"error":"Historical choice has an invalid resource requirement"}
		for resource_id: Variant in choice.resource_deltas:
			if not resource_id is String or not _is_integral_number(choice.resource_deltas[resource_id]) or int(choice.resource_deltas[resource_id]) == 0:
				return {"ok":false,"error":"Historical choice has an invalid resource delta"}
		var follow_up: Variant = choice.get("follow_up",{})
		if not follow_up is Dictionary:
			return {"ok":false,"error":"Historical choice follow-up must be an object"}
		if not follow_up.is_empty() and (not follow_up.get("event_id","") is String or str(follow_up.get("event_id","")).is_empty() or not _is_integral_number(follow_up.get("delay_minutes",null)) or int(follow_up.delay_minutes) < 1):
			return {"ok":false,"error":"Historical choice follow-up metadata is invalid"}
		has_baseline = has_baseline or str(choice.id) == str(definition.baseline_choice_id)
	if not has_baseline:
		return {"ok":false,"error":"Historical event baseline choice does not exist"}
	return {"ok":true}

static func _is_integral_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or (typeof(value) == TYPE_FLOAT and value == floor(value))
