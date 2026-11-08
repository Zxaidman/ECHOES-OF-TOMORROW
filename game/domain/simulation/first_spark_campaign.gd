class_name FirstSparkCampaign
extends RefCounted
## Derives the First Spark objective chain from authoritative simulation state.
## No objective flags are persisted separately, preventing UI/domain desynchronization.

const TARGET_INVENTION: String = "improved_seed_selection"

func get_objectives(simulation: Variant) -> Array[Dictionary]:
	var timeline_records: Dictionary = {}
	for entry: Dictionary in simulation.timeline.get_timeline_entries():
		timeline_records[str(entry.id)] = entry
	var harvest_done: bool = _timeline_resolved(timeline_records, "harvest_crisis")
	var compact_done: bool = _timeline_resolved(timeline_records, "village_compact")
	var crop_known: bool = simulation.knowledge.is_knowledge_known("crop_selection")
	var invention_status: String = simulation.knowledge.get_invention_status(TARGET_INVENTION)
	var production_ready: bool = invention_status == "production_ready"
	var first_batch_done: bool = simulation.knowledge.get_production_runs(TARGET_INVENTION) > 0
	return [
		{"id":"harvest_crisis","title":"Resolve the harvest crisis","description":"Make a decision that determines how the village responds to the threatened harvest.","complete":harvest_done},
		{"id":"village_compact","title":"Shape the village compact","description":"Resolve the follow-up decision and establish how the settlement will cooperate.","complete":compact_done},
		{"id":"crop_selection","title":"Research selective seed cultivation","description":"Study the agricultural method needed to improve the next generation of crops.","complete":crop_known},
		{"id":"seed_production","title":"Commission improved seed production","description":"Build and validate a prototype, then make its production process available.","complete":production_ready},
		{"id":"first_batch","title":"Produce the first improved batch","description":"Run the commissioned recipe to turn tools into a larger food reserve.","complete":first_batch_done}
	]

func get_progress(simulation: Variant) -> Dictionary:
	var objectives: Array[Dictionary] = get_objectives(simulation)
	var completed: int = 0
	for objective: Dictionary in objectives:
		if bool(objective.complete):
			completed += 1
	return {"completed":completed,"total":objectives.size(),"is_complete":completed == objectives.size(),"objectives":objectives}

func _timeline_resolved(records: Dictionary, event_id: String) -> bool:
	if not records.has(event_id):
		return false
	return ["altered","preserved"].has(str(records[event_id].get("status","")))
