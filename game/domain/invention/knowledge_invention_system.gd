class_name KnowledgeInventionSystem
extends RefCounted
## Deterministic data-driven progression from theoretical knowledge to production.

const ContentCatalog = preload("res://game/infrastructure/content/content_catalog.gd")
const STATES: Array[String] = ["available", "prototype_built", "validated", "production_ready"]
var _knowledge: Dictionary = {}
var _inventions: Dictionary = {}
var _known: Dictionary = {}
var _progress: Dictionary = {}
var _ready: bool = false

func initialize() -> Dictionary:
	var knowledge_result: Dictionary = ContentCatalog.load_collection("res://content/knowledge.json", "knowledge")
	var invention_result: Dictionary = ContentCatalog.load_collection("res://content/inventions.json", "inventions")
	var resource_result: Dictionary = ContentCatalog.load_collection("res://content/resources.json", "resources")
	if not knowledge_result.ok:
		return knowledge_result
	if not invention_result.ok:
		return invention_result
	if not resource_result.ok:
		return resource_result
	var resource_ids: Dictionary = {}
	for resource: Dictionary in resource_result.items:
		resource_ids[str(resource.id)] = true
	var knowledge_defs: Dictionary = {}
	for item: Dictionary in knowledge_result.items:
		if not item.get("name","") is String or not item.get("description","") is String or typeof(item.get("known_at_start",null)) != TYPE_BOOL or not item.get("prerequisites",null) is Array or not item.get("study_cost",null) is Dictionary or not item.get("skill_requirements",null) is Dictionary:
			return {"ok":false,"error":"Invalid knowledge definition: %s" % str(item.get("id",""))}
		if not _valid_cost(item.study_cost) or not _has_known_resources(item.study_cost,resource_ids) or not _valid_skills(item.skill_requirements):
			return {"ok":false,"error":"Invalid knowledge cost or skill: %s" % str(item.id)}
		knowledge_defs[str(item.id)] = item.duplicate(true)
	for item_id: String in knowledge_defs:
		for prerequisite: Variant in knowledge_defs[item_id].prerequisites:
			if not prerequisite is String or not knowledge_defs.has(str(prerequisite)) or prerequisite == item_id:
				return {"ok":false,"error":"Invalid knowledge prerequisite: %s" % item_id}
	if not _acyclic(knowledge_defs,"prerequisites"):
		return {"ok":false,"error":"Knowledge prerequisite cycle detected"}
	var invention_defs: Dictionary = {}
	for item: Dictionary in invention_result.items:
		for field: String in ["name","category","description","validation_skill","facility_required"]:
			if not item.get(field,"") is String or str(item.get(field,"")).is_empty():
				return {"ok":false,"error":"Invalid invention field: %s" % field}
		for field: String in ["knowledge_required","invention_prerequisites"]:
			if not item.get(field,null) is Array:
				return {"ok":false,"error":"Invalid invention prerequisites: %s" % str(item.get("id",""))}
		for field: String in ["prototype_cost","skill_requirements","production_cost","production_output"]:
			if not item.get(field,null) is Dictionary:
				return {"ok":false,"error":"Invalid invention requirements: %s" % str(item.get("id",""))}
		if not _valid_cost(item.prototype_cost) or not _valid_cost(item.production_cost) or not _valid_cost(item.production_output) or not _has_known_resources(item.prototype_cost,resource_ids) or not _has_known_resources(item.production_cost,resource_ids) or not _has_known_resources(item.production_output,resource_ids) or not _valid_skills(item.skill_requirements):
			return {"ok":false,"error":"Invalid invention costs or skills: %s" % str(item.id)}
		if item.production_cost.is_empty() or item.production_output.is_empty() or not _valid_stat(item.get("validation_min",null)):
			return {"ok":false,"error":"Invalid production recipe or validation threshold: %s" % str(item.id)}
		invention_defs[str(item.id)] = item.duplicate(true)
	for item_id: String in invention_defs:
		var item: Dictionary = invention_defs[item_id]
		for knowledge_id: Variant in item.knowledge_required:
			if not knowledge_id is String or not knowledge_defs.has(str(knowledge_id)):
				return {"ok":false,"error":"Unknown knowledge dependency in %s" % item_id}
		for prerequisite: Variant in item.invention_prerequisites:
			if not prerequisite is String or not invention_defs.has(str(prerequisite)) or prerequisite == item_id:
				return {"ok":false,"error":"Unknown invention dependency in %s" % item_id}
	if not _acyclic(invention_defs,"invention_prerequisites"):
		return {"ok":false,"error":"Invention prerequisite cycle detected"}
	_knowledge = knowledge_defs
	_inventions = invention_defs
	_known.clear()
	_progress.clear()
	for item_id: String in _knowledge:
		if bool(_knowledge[item_id].get("known_at_start",false)):
			_known[item_id] = true
	for item_id: String in _inventions:
		_progress[item_id] = {"status":"available","prototype_attempts":0,"validation_attempts":0,"last_failure":"","production_runs":0}
	_ready = true
	return {"ok":true,"knowledge_count":_knowledge.size(),"invention_count":_inventions.size()}

func study_knowledge(item_id: String, population: PopulationSimulation, ledger: ResourceLedger) -> Dictionary:
	if not _ready or not _knowledge.has(item_id):
		return {"ok":false,"error":"Unknown knowledge: %s" % item_id}
	if _known.has(item_id):
		return {"ok":false,"error":"Knowledge is already understood"}
	var definition: Dictionary = _knowledge[item_id]
	for prerequisite: String in definition.prerequisites:
		if not _known.has(prerequisite):
			return {"ok":false,"error":"Missing prerequisite knowledge: %s" % prerequisite}
	var skill_check: Dictionary = _check_skills(definition.skill_requirements,population)
	if not skill_check.ok:
		return skill_check
	var payment: Dictionary = _pay(definition.study_cost,ledger)
	if not payment.ok:
		return payment
	_known[item_id] = true
	return {"ok":true,"knowledge_id":item_id}

func attempt_prototype(item_id: String, population: PopulationSimulation, ledger: ResourceLedger) -> Dictionary:
	if not _ready or not _inventions.has(item_id):
		return {"ok":false,"error":"Unknown invention: %s" % item_id}
	var progress: Dictionary = _progress[item_id]
	if str(progress.status) != "available":
		return {"ok":false,"error":"Invention is not awaiting a prototype"}
	var definition: Dictionary = _inventions[item_id]
	for knowledge_id: String in definition.knowledge_required:
		if not _known.has(knowledge_id):
			return {"ok":false,"error":"Missing knowledge: %s" % knowledge_id}
	for prerequisite: String in definition.invention_prerequisites:
		if not ["validated","production_ready"].has(str(_progress[prerequisite].status)):
			return {"ok":false,"error":"Missing validated invention: %s" % prerequisite}
	var skill_check: Dictionary = _check_skills(definition.skill_requirements,population)
	if not skill_check.ok:
		return skill_check
	var payment: Dictionary = _pay(definition.prototype_cost,ledger)
	if not payment.ok:
		return payment
	progress.status = "prototype_built"
	progress.prototype_attempts = int(progress.prototype_attempts) + 1
	progress.last_failure = ""
	_progress[item_id] = progress
	return {"ok":true,"status":"prototype_built"}

func test_prototype(item_id: String, population: PopulationSimulation) -> Dictionary:
	if not _inventions.has(item_id) or str(_progress.get(item_id,{}).get("status","")) != "prototype_built":
		return {"ok":false,"error":"A built prototype is required"}
	var definition: Dictionary = _inventions[item_id]
	var score: int = population.get_best_skill(str(definition.validation_skill))
	var progress: Dictionary = _progress[item_id]
	progress.validation_attempts = int(progress.validation_attempts) + 1
	if score < int(definition.validation_min):
		progress.last_failure = "%s skill %d is below validation threshold %d" % [str(definition.validation_skill),score,int(definition.validation_min)]
		_progress[item_id] = progress
		return {"ok":true,"validated":false,"score":score,"required":int(definition.validation_min),"reason":str(progress.last_failure)}
	progress.status = "validated"
	progress.last_failure = ""
	_progress[item_id] = progress
	return {"ok":true,"validated":true,"score":score}

func commission_production(item_id: String) -> Dictionary:
	if not _inventions.has(item_id) or str(_progress.get(item_id,{}).get("status","")) != "validated":
		return {"ok":false,"error":"A validated prototype is required"}
	var progress: Dictionary = _progress[item_id]
	progress.status = "production_ready"
	_progress[item_id] = progress
	return {"ok":true,"status":"production_ready"}

func produce(item_id: String, ledger: ResourceLedger, facilities: Variant = null) -> Dictionary:
	if not _inventions.has(item_id) or str(_progress.get(item_id,{}).get("status","")) != "production_ready":
		return {"ok":false,"error":"Production has not been commissioned"}
	var definition: Dictionary = _inventions[item_id]
	var required_facility: String = str(definition.get("facility_required", ""))
	if not required_facility.is_empty() and (facilities == null or not facilities.has_facility(required_facility)):
		return {"ok":false,"error":"Requires facility: %s" % required_facility}
	var changes: Dictionary = {}
	for resource_id: String in definition.production_cost:
		changes[resource_id] = -int(definition.production_cost[resource_id])
	for resource_id: String in definition.production_output:
		changes[resource_id] = int(changes.get(resource_id,0)) + int(definition.production_output[resource_id])
	var result: Dictionary = ledger.apply_transaction(changes)
	if not result.ok:
		return result
	var progress: Dictionary = _progress[item_id]
	progress.production_runs = int(progress.get("production_runs", 0)) + 1
	_progress[item_id] = progress
	return {"ok":true,"outputs":definition.production_output.duplicate(true),"amounts":result.amounts,"production_runs":int(progress.production_runs)}

func get_knowledge_entries(population: PopulationSimulation, ledger: ResourceLedger) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item_id: String in _sorted(_knowledge):
		var definition: Dictionary = _knowledge[item_id]
		var missing: Array[String] = []
		for prerequisite: String in definition.prerequisites:
			if not _known.has(prerequisite):
				missing.append(prerequisite)
		var skill: Dictionary = _check_skills(definition.skill_requirements,population)
		var can_study: bool = not _known.has(item_id) and missing.is_empty() and skill.ok and _can_pay(definition.study_cost,ledger)
		result.append({"id":item_id,"name":str(definition.name),"description":str(definition.description),"known":_known.has(item_id),"can_study":can_study,"missing_knowledge":missing,"missing_skills":skill.get("error",""),"missing_resources":_missing_resources(definition.study_cost,ledger)})
	return result

func get_invention_entries(population: PopulationSimulation, ledger: ResourceLedger, facilities: Variant = null) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item_id: String in _sorted(_inventions):
		var definition: Dictionary = _inventions[item_id]
		var progress: Dictionary = _progress[item_id]
		var missing_knowledge: Array[String] = []
		var missing_inventions: Array[String] = []
		for knowledge_id: String in definition.knowledge_required:
			if not _known.has(knowledge_id):
				missing_knowledge.append(knowledge_id)
		for prerequisite: String in definition.invention_prerequisites:
			if not ["validated","production_ready"].has(str(_progress[prerequisite].status)):
				missing_inventions.append(prerequisite)
		var skills: Dictionary = _check_skills(definition.skill_requirements,population)
		var missing_resources: Array[String] = _missing_resources(definition.prototype_cost,ledger)
		var required_facility: String = str(definition.get("facility_required", ""))
		var missing_facility: bool = not required_facility.is_empty() and (facilities == null or not facilities.has_facility(required_facility))
		var visible_status: String = str(progress.status)
		if visible_status == "available" and (not missing_knowledge.is_empty() or not missing_inventions.is_empty() or not skills.ok or not missing_resources.is_empty()):
			visible_status = "locked"
		result.append({"id":item_id,"name":str(definition.name),"category":str(definition.category),"description":str(definition.description),"status":visible_status,"can_prototype":str(progress.status) == "available" and missing_knowledge.is_empty() and missing_inventions.is_empty() and skills.ok and missing_resources.is_empty(),"can_test":str(progress.status) == "prototype_built","can_commission":str(progress.status) == "validated","can_produce":str(progress.status) == "production_ready" and not missing_facility,"missing_knowledge":missing_knowledge,"missing_inventions":missing_inventions,"missing_skills":skills.get("error",""),"missing_resources":missing_resources,"missing_facility":required_facility if missing_facility else "","last_failure":str(progress.last_failure),"production_cost":definition.production_cost.duplicate(true),"production_output":definition.production_output.duplicate(true)})
	return result

func is_knowledge_known(item_id: String) -> bool:
	return _known.has(item_id)

func get_invention_status(item_id: String) -> String:
	return str(_progress.get(item_id, {}).get("status", "unknown"))

func get_production_runs(item_id: String) -> int:
	return int(_progress.get(item_id, {}).get("production_runs", 0))

func create_save_state() -> Dictionary:
	return {"known_knowledge":_known.duplicate(true),"progress":_progress.duplicate(true)}

func restore_save_state(state: Dictionary) -> Dictionary:
	if not _ready or not state.get("known_knowledge",null) is Dictionary or not state.get("progress",null) is Dictionary:
		return {"ok":false,"error":"Invalid knowledge save state"}
	var known: Dictionary = state.known_knowledge.duplicate(true)
	for item_id: Variant in known:
		if not _knowledge.has(str(item_id)) or known[item_id] != true:
			return {"ok":false,"error":"Unknown knowledge in save"}
	var progress: Dictionary = state.progress.duplicate(true)
	if progress.size() != _inventions.size():
		return {"ok":false,"error":"Invention save does not match current content"}
	for item_id: String in _inventions:
		if not progress.has(item_id) or not progress[item_id] is Dictionary:
			return {"ok":false,"error":"Missing invention save state: %s" % item_id}
		var item: Dictionary = progress[item_id]
		# 0.7.0 saves predate production counters.
		if not item.has("production_runs"):
			item["production_runs"] = 0
		if not STATES.has(str(item.get("status",""))) or not _is_integral(item.get("prototype_attempts",null)) or not _is_integral(item.get("validation_attempts",null)) or not _is_integral(item.get("production_runs",null)) or int(item.prototype_attempts) < 0 or int(item.validation_attempts) < 0 or int(item.production_runs) < 0 or int(item.production_runs) > 2147483647 or not item.get("last_failure","") is String:
			return {"ok":false,"error":"Invalid invention save state: %s" % item_id}
	_known = known
	_progress = progress
	return {"ok":true}

func _check_skills(requirements: Dictionary, population: PopulationSimulation) -> Dictionary:
	for skill_id: String in requirements:
		var actual: int = population.get_best_skill(skill_id)
		if actual < int(requirements[skill_id]):
			return {"ok":false,"error":"Requires %s skill %d; best available is %d" % [skill_id,int(requirements[skill_id]),actual]}
	return {"ok":true}

func _can_pay(costs: Dictionary, ledger: ResourceLedger) -> bool:
	return _missing_resources(costs,ledger).is_empty()

func _pay(costs: Dictionary, ledger: ResourceLedger) -> Dictionary:
	var changes: Dictionary = {}
	for resource_id: String in costs:
		changes[resource_id] = -int(costs[resource_id])
	if changes.is_empty():
		return {"ok":true}
	return ledger.apply_transaction(changes)

func _missing_resources(costs: Dictionary, ledger: ResourceLedger) -> Array[String]:
	var missing: Array[String] = []
	for resource_id: String in costs:
		var available: int = ledger.get_amount(resource_id)
		var required: int = int(costs[resource_id])
		if not ledger.has_resource(resource_id) or available < required:
			missing.append("%s %d/%d" % [resource_id,available,required])
	return missing

func _valid_cost(values: Dictionary) -> bool:
	for resource_id: Variant in values:
		if not resource_id is String or str(resource_id).is_empty() or not _is_integral(values[resource_id]) or int(values[resource_id]) <= 0 or int(values[resource_id]) > 2147483647:
			return false
	return true

func _has_known_resources(values: Dictionary, resource_ids: Dictionary) -> bool:
	for resource_id: String in values:
		if not resource_ids.has(resource_id):
			return false
	return true

func _valid_skills(values: Dictionary) -> bool:
	for skill_id: Variant in values:
		if not skill_id is String or str(skill_id).is_empty() or not _is_integral(values[skill_id]) or int(values[skill_id]) < 0 or int(values[skill_id]) > 100:
			return false
	return true

func _valid_stat(value: Variant) -> bool:
	return _is_integral(value) and int(value) >= 0 and int(value) <= 100

func _acyclic(definitions: Dictionary, dependency_field: String) -> bool:
	var visiting: Dictionary = {}
	var visited: Dictionary = {}
	for item_id: String in definitions:
		if not _visit(item_id,definitions,dependency_field,visiting,visited):
			return false
	return true

func _visit(item_id: String, definitions: Dictionary, dependency_field: String, visiting: Dictionary, visited: Dictionary) -> bool:
	if visited.has(item_id):
		return true
	if visiting.has(item_id):
		return false
	visiting[item_id] = true
	for dependency: String in definitions[item_id][dependency_field]:
		if not _visit(dependency,definitions,dependency_field,visiting,visited):
			return false
	visiting.erase(item_id)
	visited[item_id] = true
	return true

func _sorted(values: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for item_id: String in values:
		result.append(item_id)
	result.sort()
	return result

static func _is_integral(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or (typeof(value) == TYPE_FLOAT and value == floor(value))
