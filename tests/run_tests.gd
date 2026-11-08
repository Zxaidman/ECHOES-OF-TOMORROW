extends SceneTree
## Dependency-free headless test runner.
const SimulationClock = preload("res://game/domain/simulation/simulation_clock.gd")
const ContentCatalog = preload("res://game/infrastructure/content/content_catalog.gd")
const SaveManager = preload("res://game/infrastructure/persistence/save_manager.gd")
const ScheduledEventQueue = preload("res://game/domain/simulation/scheduled_event_queue.gd")
const ResourceLedger = preload("res://game/domain/settlement/resource_ledger.gd")
const RandomStreams = preload("res://game/domain/simulation/random_streams.gd")
const SettlementSimulation = preload("res://game/domain/simulation/settlement_simulation.gd")
const PopulationSimulation = preload("res://game/domain/population/population_simulation.gd")
const KnowledgeInventionSystem = preload("res://game/domain/invention/knowledge_invention_system.gd")
const NPCDialogueGateway = preload("res://game/domain/population/npc_dialogue_gateway.gd")
const HistoricalTimeline = preload("res://game/domain/simulation/historical_timeline.gd")
const FirstSparkCampaign = preload("res://game/domain/simulation/first_spark_campaign.gd")
var _failures: int = 0
var _assertions: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_clock()
	_test_content_catalog()
	_test_resource_ledger()
	_test_event_queue()
	_test_random_streams()
	_test_simulation_determinism()
	_test_simulation_save_restore()
	_test_historical_timeline()
	_test_population_simulation()
	_test_npc_memory_and_dialogue()
	_test_knowledge_inventions()
	_test_first_spark_campaign()
	_test_save_round_trip()
	print("Test summary: %d assertions, %d failures" % [_assertions, _failures])
	quit(1 if _failures > 0 else 0)

func _test_clock() -> void:
	var clock: SimulationClock = SimulationClock.new()
	_expect(clock.current_minute == 0, "clock starts at zero")
	_expect(clock.advance_time(60), "clock accepts positive time")
	_expect(clock.current_minute == 60, "clock advances exactly")
	_expect(clock.format_time() == "Day 1 · 01:00", "clock formats elapsed time")
	_expect(not clock.advance_time(-1), "clock rejects negative time")
	_expect(clock.current_minute == 60, "invalid advance does not mutate state")
	_expect(SimulationClock.new(1440).format_time() == "Day 2 · 00:00", "clock formats day boundary")

func _test_content_catalog() -> void:
	var resources: Dictionary = ContentCatalog.load_collection("res://content/resources.json", "resources")
	_expect(resources["ok"], "resource content loads")
	if resources["ok"]:
		_expect(resources["items"].size() == 6, "six starter resources exist")
	var npcs: Dictionary = ContentCatalog.load_collection("res://content/npcs.json", "npcs")
	_expect(npcs["ok"], "NPC content loads")
	if npcs["ok"]:
		_expect(npcs["items"].size() == 5, "five starter NPCs exist")

func _test_resource_ledger() -> void:
	var ledger: ResourceLedger = ResourceLedger.new()
	_expect(ledger.initialize({"food": 20, "wood": 10})["ok"], "ledger initializes")
	_expect(ledger.apply_transaction({"food": -5, "wood": 3})["ok"], "valid multi-resource transaction applies")
	_expect(ledger.get_amount("food") == 15 and ledger.get_amount("wood") == 13, "transaction applies all deltas")
	_expect(not ledger.apply_transaction({"food": -100, "wood": -1})["ok"], "insufficient transaction rejected")
	_expect(ledger.get_amount("food") == 15 and ledger.get_amount("wood") == 13, "rejected transaction is atomic")
	_expect(not ledger.apply_transaction({"gold": 1})["ok"], "unknown resource rejected")
	_expect(not ledger.apply_transaction({"food": 0.5})["ok"], "fractional resource delta rejected")

func _test_event_queue() -> void:
	var queue: ScheduledEventQueue = ScheduledEventQueue.new()
	_expect(queue.schedule("late-priority", 100, 20, "test", {})["ok"], "first event scheduled")
	_expect(queue.schedule("early-priority", 100, 10, "test", {})["ok"], "second event scheduled")
	_expect(queue.schedule("same-priority-later", 100, 10, "test", {})["ok"], "third event scheduled")
	_expect(not queue.schedule("same-priority-later", 120, 10, "test", {})["ok"], "duplicate pending ID rejected")
	_expect(not queue.schedule("past", -1, 0, "test", {})["ok"], "negative event time rejected")
	var first: Dictionary = queue.pop_next_due(100)
	var second: Dictionary = queue.pop_next_due(100)
	var third: Dictionary = queue.pop_next_due(100)
	_expect(first["id"] == "early-priority", "priority determines same-minute order")
	_expect(second["id"] == "same-priority-later", "sequence determines equal-priority order")
	_expect(third["id"] == "late-priority", "later priority runs last")
	_expect(queue.pop_next_due(100).is_empty(), "queue empty when no event due")

func _test_random_streams() -> void:
	var first: RandomStreams = RandomStreams.new(123456)
	var second: RandomStreams = RandomStreams.new(123456)
	_expect(first.world_randi_range(0, 100000) == second.world_randi_range(0, 100000), "world RNG is repeatable")
	_expect(first.economy_randi_range(0, 100000) == second.economy_randi_range(0, 100000), "economy RNG is repeatable")
	var states: Dictionary = first.to_dictionary()
	var restored: RandomStreams = RandomStreams.new(1)
	_expect(restored.restore(states)["ok"], "RNG states restore")
	_expect(first.npc_randi_range(0, 100000) == restored.npc_randi_range(0, 100000), "restored NPC RNG continues sequence")

func _test_simulation_determinism() -> void:
	var one_step: SettlementSimulation = SettlementSimulation.new(480, 777)
	var split_steps: SettlementSimulation = SettlementSimulation.new(480, 777)
	for simulation: SettlementSimulation in [one_step, split_steps]:
		simulation.schedule_resource_delta("food-use", 540, 10, "food", -10, 1440)
		simulation.schedule_resource_delta("farm-output", 600, 20, "food", 14, 1440)
	var single_result: Dictionary = one_step.advance_time(120)
	var first_half: Dictionary = split_steps.advance_time(60)
	var second_half: Dictionary = split_steps.advance_time(60)
	_expect(single_result["ok"] and first_half["ok"] and second_half["ok"], "simulation accepts valid advances")
	_expect(one_step.clock.current_minute == split_steps.clock.current_minute, "split and single advances reach same time")
	_expect(one_step.resources.to_dictionary() == split_steps.resources.to_dictionary(), "split and single advances preserve resources")
	_expect(one_step.events.to_array() == split_steps.events.to_array(), "split and single advances preserve queue")
	_expect(one_step.event_log.size() == split_steps.event_log.size(), "split and single advances process same event count")
	_expect(one_step.resources.get_amount("food") == 111, "consumption and production resolve correctly")
	_expect(not one_step.advance_time(-1)["ok"], "simulation rejects negative advance")
	_expect(not one_step.schedule_resource_delta("past-event", 100, 0, "food", -1)["ok"], "simulation rejects events scheduled in the past")

func _test_simulation_save_restore() -> void:
	var original: SettlementSimulation = SettlementSimulation.new(480, 999)
	original.schedule_resource_delta("food-use", 540, 10, "food", -10, 1440)
	original.advance_time(60)
	var restored: SettlementSimulation = SettlementSimulation.new()
	var result: Dictionary = restored.restore_save_state(original.clock.current_minute, original.create_save_state())
	_expect(result["ok"], "simulation state restores")
	_expect(restored.resources.to_dictionary() == original.resources.to_dictionary(), "restored resources match")
	_expect(restored.events.to_array() == original.events.to_array(), "restored event queue matches")
	_expect(restored.random_streams.to_dictionary() == original.random_streams.to_dictionary(), "restored RNG states match")
	original.advance_time(1440)
	restored.advance_time(1440)
	_expect(restored.resources.to_dictionary() == original.resources.to_dictionary(), "restored simulation continues deterministically")

func _test_first_spark_campaign() -> void:
	var simulation: SettlementSimulation = SettlementSimulation.new(480, 321)
	var campaign: FirstSparkCampaign = FirstSparkCampaign.new()
	var initial: Dictionary = campaign.get_progress(simulation)
	_expect(initial.completed == 0 and initial.total == 5 and not initial.is_complete, "First Spark begins with five incomplete objectives")
	_expect(simulation.advance_time(120).ok, "First Spark reaches its harvest decision")
	_expect(simulation.resolve_historical_choice("harvest_crisis", "organize_harvest").ok, "First Spark resolves the harvest crisis")
	_expect(simulation.advance_time(1440).ok, "First Spark reaches its follow-up decision")
	_expect(simulation.resolve_historical_choice("village_compact", "keep_customs").ok, "First Spark resolves the village compact")
	_expect(simulation.knowledge.study_knowledge("crop_selection", simulation.population, simulation.resources).ok, "First Spark researches selective seed cultivation")
	_expect(simulation.knowledge.attempt_prototype("improved_seed_selection", simulation.population, simulation.resources).ok, "First Spark builds the seed-selection prototype")
	var validation: Dictionary = simulation.knowledge.test_prototype("improved_seed_selection", simulation.population)
	_expect(validation.ok and validation.validated, "First Spark validates the prototype")
	_expect(simulation.knowledge.commission_production("improved_seed_selection").ok, "First Spark commissions improved seed production")
	var before_production: Dictionary = campaign.get_progress(simulation)
	_expect(before_production.completed == 4 and not before_production.is_complete, "First Spark remains incomplete until a production batch is made")
	_expect(simulation.knowledge.produce("improved_seed_selection", simulation.resources).ok, "First Spark produces its first improved batch")
	var completed: Dictionary = campaign.get_progress(simulation)
	_expect(completed.is_complete and completed.completed == completed.total, "First Spark completes only after the first production batch")
	var saved_state: Dictionary = simulation.create_save_state()
	var restored: SettlementSimulation = SettlementSimulation.new()
	_expect(restored.restore_save_state(simulation.clock.current_minute, saved_state).ok, "First Spark campaign restores")
	_expect(campaign.get_progress(restored).is_complete, "First Spark objective completion survives save and restore")
	_expect(restored.knowledge.get_production_runs("improved_seed_selection") == 1, "Production history survives save and restore")

func _test_save_round_trip() -> void:
	var manager: SaveManager = SaveManager.new()
	var save_path: String = "user://test_saves/test_campaign.json"
	var simulation: SettlementSimulation = SettlementSimulation.new()
	simulation.schedule_resource_delta("daily-food", 540, 10, "food", -10, 1440)
	var snapshot: Dictionary = {"campaign_id": "test-campaign", "simulation_minute": simulation.clock.current_minute, "state": simulation.create_save_state()}
	var saved: Dictionary = manager.save_snapshot(save_path, snapshot)
	_expect(saved["ok"], "save snapshot writes")
	var loaded: Dictionary = manager.load_snapshot(save_path)
	_expect(loaded["ok"], "save snapshot loads")
	if loaded["ok"]:
		_expect(loaded["data"]["campaign_id"] == "test-campaign", "save preserves campaign ID")
		_expect(loaded["data"]["simulation_minute"] == simulation.clock.current_minute, "save preserves simulation time")
		var restored: SettlementSimulation = SettlementSimulation.new()
		var restore_result: Dictionary = restored.restore_save_state(loaded["data"]["simulation_minute"], loaded["data"]["state"])
		_expect(restore_result["ok"], "campaign snapshot restores simulation: " + str(restore_result.get("error", "")))
		_expect(restored.events.to_array() == simulation.events.to_array(), "snapshot preserves pending events")
		var continued: Dictionary = restored.advance_time(60)
		_expect(continued["ok"], "JSON-restored simulation continues")
		_expect(restored.resources.get_amount("food") == 97, "JSON-restored event applies resource delta")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + ".bak"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_saves"))

func _expect(condition: bool, message: String) -> void:
	_assertions += 1
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)

func _test_historical_timeline() -> void:
	var simulation: SettlementSimulation = SettlementSimulation.new(480,321)
	_expect(simulation.timeline.get_scheduled_events().size() == 1, "timeline schedules only its authored root event")
	_expect(not simulation.resolve_historical_choice("harvest_crisis","organize_harvest").ok, "historical choice cannot resolve before its event triggers")
	var advance: Dictionary = simulation.advance_time(120)
	_expect(advance.ok, "simulation advances to the first historical event")
	var pending: Array[Dictionary] = simulation.timeline.get_pending_events()
	_expect(pending.size() == 1 and pending[0].id == "harvest_crisis", "historical event becomes a player decision when triggered")
	var food_before: int = simulation.resources.get_amount("food")
	var tools_before: int = simulation.resources.get_amount("tools")
	var invalid: Dictionary = simulation.resolve_historical_choice("harvest_crisis","unknown_choice")
	_expect(not invalid.ok, "unknown historical choice is rejected")
	_expect(simulation.resources.get_amount("food") == food_before and simulation.resources.get_amount("tools") == tools_before, "invalid historical choice has no resource side effects")
	var choice: Dictionary = simulation.resolve_historical_choice("harvest_crisis","organize_harvest")
	_expect(choice.ok, "valid historical choice resolves")
	_expect(simulation.resources.get_amount("food") == food_before + 8 and simulation.resources.get_amount("tools") == tools_before - 1, "historical choice applies its atomic resource consequences")
	_expect(simulation.population.get_relationship("aldwin","elin").trust == 58, "historical choice changes the authored NPC relationship")
	_expect(simulation.population.get_memory_count("elin") == 1, "historical consequence is recorded in the affected NPC memory")
	var first_entry: Dictionary = {}
	for entry: Dictionary in simulation.timeline.get_timeline_entries():
		if entry.id == "harvest_crisis":
			first_entry = entry
	_expect(first_entry.get("status","") == "altered" and first_entry.get("changed",false), "timeline distinguishes an altered historical outcome")
	_expect(simulation.timeline.get_scheduled_events().size() == 1, "resolved event activates its causal follow-up")
	var saved_state: Dictionary = simulation.create_save_state()
	var restored: SettlementSimulation = SettlementSimulation.new()
	_expect(restored.restore_save_state(simulation.clock.current_minute,saved_state).ok, "historical timeline restores with campaign state")
	_expect(restored.create_save_state() == saved_state, "timeline and simulation snapshots round-trip exactly")
	var follow_up: Dictionary = restored.advance_time(1440)
	_expect(follow_up.ok and restored.timeline.get_pending_events().size() == 1, "causal follow-up becomes a pending event")
	var second_choice: Dictionary = restored.resolve_historical_choice("village_compact","keep_customs")
	_expect(second_choice.ok, "follow-up event accepts a valid choice")
	var second_entry: Dictionary = {}
	for entry: Dictionary in restored.timeline.get_timeline_entries():
		if entry.id == "village_compact":
			second_entry = entry
	_expect(second_entry.get("status","") == "preserved" and not second_entry.get("changed",true), "baseline choice is recorded as preserved history")
	var legacy_simulation: SettlementSimulation = SettlementSimulation.new(480,321)
	var legacy_state: Dictionary = legacy_simulation.create_save_state()
	legacy_state.erase("timeline")
	var migrated: SettlementSimulation = SettlementSimulation.new()
	_expect(migrated.restore_save_state(legacy_simulation.clock.current_minute,legacy_state).ok, "0.6.0 save migrates by initializing the new timeline")
	var tampered: Dictionary = saved_state.duplicate(true)
	tampered.timeline.records.harvest_crisis.status = "altered"
	tampered.timeline.records.harvest_crisis.changed = false
	var rejected: SettlementSimulation = SettlementSimulation.new()
	_expect(not rejected.restore_save_state(simulation.clock.current_minute,tampered).ok, "inconsistent timeline save metadata is rejected")

func _test_population_simulation() -> void:
	var population: PopulationSimulation = PopulationSimulation.new()
	_expect(population.get_population_count() == 25, "population includes five named NPCs and twenty background residents")
	_expect(population.get_npc("mara").get("role", "") == "Village healer", "named NPC template is instantiated")
	_expect(population.get_activity_at("mara", 8 * 60) == "working", "NPC schedule resolves working hours")
	_expect(population.get_activity_at("mara", 23 * 60) == "sleeping", "NPC schedule resolves sleep hours")
	var before: Dictionary = population.get_npc("mara")
	var ledger: ResourceLedger = ResourceLedger.new()
	ledger.initialize({"food":30})
	var tick: Dictionary = population.tick_hour(9 * 60, ledger)
	_expect(tick["ok"], "population hourly tick succeeds")
	_expect(ledger.get_amount("food") == 17, "population food upkeep is charged atomically")
	_expect(int(population.get_npc("mara")["needs"]["hunger"]) > int(before["needs"]["hunger"]), "hunger increases over time")
	_expect(population.set_relationship("mara","edric",{"trust":72,"cooperation":65,"conflict":8})["ok"], "directional relationship can be updated")
	_expect(population.get_relationship("mara","edric")["trust"] == 72, "relationship values are readable")
	_expect(population.get_relationship("edric","mara")["trust"] == 50, "relationships are directional")
	var restored: PopulationSimulation = PopulationSimulation.new()
	_expect(restored.restore_save_state(population.create_save_state())["ok"], "population state restores")
	_expect(restored.create_save_state() == population.create_save_state(), "population snapshot round-trips exactly")
	_expect(not restored.set_relationship("unknown","edric",{"trust":10})["ok"], "unknown NPC relationship target rejected")

func _test_npc_memory_and_dialogue() -> void:
	var population: PopulationSimulation = PopulationSimulation.new()
	var memory: Dictionary = {"id":"memory-001","event_id":"event-001","timestamp_minute":1000,"summary":"Mara treated Elin after a harvest accident.","importance":80,"source":"witnessed","confidence":100,"participants":["mara","elin"],"tags":["medicine","harvest"]}
	_expect(population.record_memory("mara",memory)["ok"], "NPC accepts a valid structured memory")
	_expect(not population.record_memory("unknown",memory)["ok"], "unknown NPC cannot receive memories")
	_expect(not population.record_memory("mara",{"id":"bad"})["ok"], "incomplete memory is rejected")
	_expect(not population.record_memory("mara",memory)["ok"], "duplicate memory ID is rejected")
	var retrieved: Array = population.retrieve_memories("mara",["medicine"],["elin"],1100,5)
	_expect(retrieved.size() == 1 and retrieved[0].id == "memory-001", "memory retrieval matches topic and participant")
	_expect(population.retrieve_memories("edric",["medicine"],["elin"],1100,5).is_empty(), "NPC cannot retrieve another NPC's private memory")
	_expect(population.retrieve_memories("mara",[],[],1000 + 80 * 43200,5).is_empty(), "memory importance decays deterministically to expiry")
	var memory_snapshot: Dictionary = population.create_save_state()
	var restored: PopulationSimulation = PopulationSimulation.new()
	_expect(restored.restore_save_state(memory_snapshot)["ok"], "NPC memories restore from campaign state")
	_expect(restored.create_save_state() == memory_snapshot, "NPC memory state round-trips exactly")
	var legacy_snapshot: Dictionary = memory_snapshot.duplicate(true)
	legacy_snapshot.erase("memories")
	var legacy_restored: PopulationSimulation = PopulationSimulation.new()
	_expect(legacy_restored.restore_save_state(legacy_snapshot)["ok"], "0.5.0 population save migrates with empty NPC memories")
	var gateway: NPCDialogueGateway = NPCDialogueGateway.new()
	var request_result: Dictionary = gateway.build_request("talk-001",population.get_npc("mara"),"What happened to Elin?","At the village clinic.",retrieved)
	_expect(request_result.ok, "dialogue request is built from bounded NPC context")
	if not request_result.ok:
		return
	var request: Dictionary = request_result.request
	var fallback: Dictionary = gateway.offline_response(request)
	_expect(fallback.intent == "none" and not str(fallback.dialogue_text).is_empty(), "offline dialogue fallback is deterministic and non-mutating")
	var valid_response: Dictionary = fallback.duplicate(true)
	valid_response.dialogue_text = "I treated her after the harvest accident."
	valid_response.referenced_memory_ids = ["memory-001"]
	_expect(gateway.validate_response(request,valid_response).ok, "valid structured dialogue proposal passes validation")
	var invalid_response: Dictionary = valid_response.duplicate(true)
	invalid_response["resource_delta"] = 999
	_expect(not gateway.validate_response(request,invalid_response).ok, "AI response with an unapproved state mutation is rejected")
	invalid_response = valid_response.duplicate(true)
	invalid_response.referenced_memory_ids = ["memory-not-provided"]
	_expect(not gateway.validate_response(request,invalid_response).ok, "AI cannot cite memories outside supplied context")
	invalid_response = valid_response.duplicate(true)
	invalid_response.intent = "delete_campaign"
	_expect(not gateway.validate_response(request,invalid_response).ok, "AI intent outside the allowlist is rejected")
	_expect(population.create_save_state() == memory_snapshot, "dialogue validation cannot mutate authoritative NPC state")

func _test_knowledge_inventions() -> void:
	var system: KnowledgeInventionSystem = KnowledgeInventionSystem.new()
	var initialized: Dictionary = system.initialize()
	_expect(initialized["ok"], "knowledge and invention catalog initializes")
	if not initialized["ok"]:
		return
	_expect(int(initialized["knowledge_count"]) == 12, "twelve knowledge entries load")
	_expect(int(initialized["invention_count"]) == 9, "nine inventions load across three chains")
	_expect(SettlementSimulation.new().resources.get_amount("iron_ore") == 30, "starting resources are loaded from authored content")
	var population: PopulationSimulation = PopulationSimulation.new()
	var ledger: ResourceLedger = ResourceLedger.new()
	ledger.initialize({"food":120,"wood":80,"stone":45,"iron_ore":30,"tools":18,"medicine":6})
	_expect(system.study_knowledge("crop_selection",population,ledger)["ok"], "player can study knowledge with prerequisites and skill")
	_expect(not system.study_knowledge("carbon_control",population,ledger)["ok"], "knowledge with missing prerequisites is blocked")
	_expect(system.attempt_prototype("improved_seed_selection",population,ledger)["ok"], "known invention can begin prototyping")
	var tested: Dictionary = system.test_prototype("improved_seed_selection",population)
	_expect(tested["ok"] and tested["validated"], "prototype validation succeeds when skill threshold is met")
	_expect(system.study_knowledge("bloomery_operation",population,ledger)["ok"], "metallurgy knowledge can be studied")
	_expect(not system.attempt_prototype("wrought_iron_tools",population,ledger)["ok"], "metallurgy chain respects invention prerequisites")
	_expect(system.attempt_prototype("bloomery_furnace",population,ledger)["ok"], "metallurgy prototype can be built")
	_expect(system.test_prototype("bloomery_furnace",population)["validated"], "metallurgy prototype validates")
	_expect(system.study_knowledge("hydraulics",population,ledger)["ok"], "mechanical knowledge can be studied")
	_expect(system.attempt_prototype("waterwheel",population,ledger)["ok"], "mechanical prototype can be built")
	_expect(system.test_prototype("waterwheel",population)["validated"], "mechanical prototype validates")
	_expect(system.commission_production("improved_seed_selection")["ok"], "validated invention can commission production")
	var food_before: int = ledger.get_amount("food")
	var tools_before: int = ledger.get_amount("tools")
	var produced: Dictionary = system.produce("improved_seed_selection",ledger)
	_expect(produced["ok"], "commissioned production recipe executes")
	_expect(system.get_production_runs("improved_seed_selection") == 1, "successful production increments the persisted run counter")
	_expect(ledger.get_amount("food") == food_before + 6 and ledger.get_amount("tools") == tools_before - 1, "production applies inputs and outputs atomically")
	_expect(not system.commission_production("crop_rotation")["ok"], "unvalidated invention cannot be commissioned")
	var snapshot: Dictionary = system.create_save_state()
	var restored: KnowledgeInventionSystem = KnowledgeInventionSystem.new()
	_expect(restored.initialize()["ok"], "knowledge content initializes before restore")
	_expect(restored.restore_save_state(snapshot)["ok"], "knowledge and invention progress restores")
	_expect(restored.create_save_state() == snapshot, "knowledge and invention snapshot round-trips")
	var legacy_progress: Dictionary = snapshot.duplicate(true)
	for invention_id: String in legacy_progress.progress:
		legacy_progress.progress[invention_id].erase("production_runs")
	var legacy_progress_restore: KnowledgeInventionSystem = KnowledgeInventionSystem.new()
	legacy_progress_restore.initialize()
	_expect(legacy_progress_restore.restore_save_state(legacy_progress).ok, "0.7.0 invention progress migrates without production counters")
	_expect(legacy_progress_restore.get_production_runs("improved_seed_selection") == 0, "legacy production counter defaults to zero")
	_expect(not restored.restore_save_state({"known_knowledge":{"not_real":true},"progress":{}})["ok"], "unknown knowledge in save is rejected")
	var legacy_simulation: SettlementSimulation = SettlementSimulation.new()
	var legacy_state: Dictionary = legacy_simulation.create_save_state()
	legacy_state.erase("knowledge")
	var migrated_simulation: SettlementSimulation = SettlementSimulation.new()
	_expect(migrated_simulation.restore_save_state(legacy_simulation.clock.current_minute,legacy_state)["ok"], "0.4.0 campaign state migrates with starting knowledge defaults")
