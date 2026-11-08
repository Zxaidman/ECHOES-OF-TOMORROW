class_name FacilitySimulation
extends RefCounted
const ContentCatalog = preload("res://game/infrastructure/content/content_catalog.gd")
const MAX_MINUTE: int = 2147483647
var _definitions: Dictionary = {}
var _instances: Dictionary = {}
var _ready: bool = false
func initialize() -> Dictionary:
	var result: Dictionary = ContentCatalog.load_collection("res://content/facilities.json", "facilities")
	if not result.ok: return result
	var knowledge_result: Dictionary = ContentCatalog.load_collection("res://content/knowledge.json", "knowledge")
	if not knowledge_result.ok: return knowledge_result
	var knowledge_ids: Dictionary = {}
	for knowledge: Dictionary in knowledge_result.items: knowledge_ids[str(knowledge.id)] = true
	var resource_result: Dictionary = ContentCatalog.load_collection("res://content/resources.json", "resources")
	if not resource_result.ok: return resource_result
	var resource_ids: Dictionary = {}
	for resource: Dictionary in resource_result.items: resource_ids[str(resource.id)] = true
	var definitions: Dictionary = {}
	var starting_count: int = 0
	for item: Dictionary in result.items:
		if not item.get("name", null) is String or not item.get("build_cost", null) is Dictionary or not item.get("required_knowledge", null) is Array or typeof(item.get("starting", null)) != TYPE_BOOL:
			return {"ok": false, "error": "Invalid facility definition: %s" % str(item.get("id", ""))}
		if bool(item.starting): starting_count += 1
		for knowledge_id: Variant in item.required_knowledge:
			if not knowledge_id is String or not knowledge_ids.has(str(knowledge_id)):
				return {"ok": false, "error": "Unknown knowledge prerequisite in facility: %s" % str(item.get("id", ""))}
		for resource_id: Variant in item.build_cost:
			var amount: Variant = item.build_cost[resource_id]
			if not resource_id is String or not resource_ids.has(str(resource_id)) or not _is_integral(amount) or int(amount) <= 0:
				return {"ok": false, "error": "Invalid facility build cost: %s" % str(item.get("id", ""))}
		definitions[str(item.id)] = item.duplicate(true)
	if starting_count != 1:
		return {"ok": false, "error": "Facility content must define exactly one starting facility"}
	_definitions = definitions
	_instances.clear()
	for facility_id: String in _definitions:
		if bool(_definitions[facility_id].starting):
			_instances[facility_id] = {"id": "facility-" + facility_id, "type_id": facility_id, "built_minute": 0}
	_ready = true
	return {"ok": true, "facility_count": _definitions.size()}
func has_facility(facility_id: String) -> bool:
	return _instances.has(facility_id)
func build(facility_id: String, knowledge: KnowledgeInventionSystem, ledger: ResourceLedger, current_minute: int) -> Dictionary:
	if not _ready or not _definitions.has(facility_id): return {"ok": false, "error": "Unknown facility: %s" % facility_id}
	if current_minute < 0 or current_minute > MAX_MINUTE: return {"ok": false, "error": "Invalid construction time"}
	if _instances.has(facility_id): return {"ok": false, "error": "Facility already exists: %s" % facility_id}
	var definition: Dictionary = _definitions[facility_id]
	if bool(definition.starting): return {"ok": false, "error": "Starting facility cannot be constructed"}
	for knowledge_id: String in definition.required_knowledge:
		if not knowledge.is_knowledge_known(knowledge_id): return {"ok": false, "error": "Requires knowledge: %s" % knowledge_id}
	var changes: Dictionary = {}
	for resource_id: String in definition.build_cost: changes[resource_id] = -int(definition.build_cost[resource_id])
	if not changes.is_empty():
		var payment: Dictionary = ledger.apply_transaction(changes)
		if not payment.ok: return payment
	var instance: Dictionary = {"id": "facility-" + facility_id, "type_id": facility_id, "built_minute": current_minute}
	_instances[facility_id] = instance
	return {"ok": true, "facility": instance.duplicate(true)}
func get_entries(knowledge: KnowledgeInventionSystem, ledger: ResourceLedger) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var ids: Array[String] = []
	for facility_id: String in _definitions: ids.append(facility_id)
	ids.sort()
	for facility_id: String in ids:
		var definition: Dictionary = _definitions[facility_id]
		var missing_knowledge: Array[String] = []
		for knowledge_id: String in definition.required_knowledge:
			if not knowledge.is_knowledge_known(knowledge_id): missing_knowledge.append(knowledge_id)
		var missing_resources: Array[String] = []
		for resource_id: String in definition.build_cost:
			var required: int = int(definition.build_cost[resource_id])
			var available: int = ledger.get_amount(resource_id)
			if available < required: missing_resources.append("%s %d/%d" % [resource_id, available, required])
		result.append({"id": facility_id, "name": str(definition.name), "built": _instances.has(facility_id), "can_build": not bool(definition.starting) and not _instances.has(facility_id) and missing_knowledge.is_empty() and missing_resources.is_empty(), "missing_knowledge": missing_knowledge, "missing_resources": missing_resources})
	return result
func create_save_state() -> Dictionary:
	return {"instances": _instances.duplicate(true)}
func restore_save_state(state: Dictionary) -> Dictionary:
	if not _ready or not state.get("instances", null) is Dictionary: return {"ok": false, "error": "Invalid facility save state"}
	var restored: Dictionary = {}
	for facility_id: Variant in state.instances:
		if not facility_id is String or not _definitions.has(str(facility_id)) or not state.instances[facility_id] is Dictionary: return {"ok": false, "error": "Unknown facility in save"}
		var instance: Dictionary = state.instances[facility_id]
		if str(instance.get("id", "")) != "facility-" + str(facility_id) or str(instance.get("type_id", "")) != str(facility_id) or not _is_integral(instance.get("built_minute", null)) or int(instance.built_minute) < 0 or int(instance.built_minute) > MAX_MINUTE:
			return {"ok": false, "error": "Invalid facility instance: %s" % str(facility_id)}
		var normalized_instance: Dictionary = instance.duplicate(true)
		normalized_instance["built_minute"] = int(instance.built_minute)
		restored[str(facility_id)] = normalized_instance
	for facility_id: String in _definitions:
		if bool(_definitions[facility_id].starting) and not restored.has(facility_id): return {"ok": false, "error": "Save is missing starting facility: %s" % facility_id}
	_instances = restored
	return {"ok": true}
func get_instances() -> Dictionary:
	return _instances.duplicate(true)

static func _is_integral(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or (typeof(value) == TYPE_FLOAT and value == floor(value))
