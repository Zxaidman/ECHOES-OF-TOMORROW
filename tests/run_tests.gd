extends SceneTree
## Dependency-free headless test runner.
const SimulationClock = preload("res://game/domain/simulation/simulation_clock.gd")
const ContentCatalog = preload("res://game/infrastructure/content/content_catalog.gd")
const SaveManager = preload("res://game/infrastructure/persistence/save_manager.gd")
const ScheduledEventQueue = preload("res://game/domain/simulation/scheduled_event_queue.gd")
const ResourceLedger = preload("res://game/domain/settlement/resource_ledger.gd")
const RandomStreams = preload("res://game/domain/simulation/random_streams.gd")
const SettlementSimulation = preload("res://game/domain/simulation/settlement_simulation.gd")
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
	_expect(one_step.resources.get_amount("food") == 124, "consumption and production resolve correctly")
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
		print("Loaded save state keys: ", loaded["data"]["state"].keys())
		print("Loaded save state: ", loaded["data"]["state"])
		_expect(loaded["data"]["campaign_id"] == "test-campaign", "save preserves campaign ID")
		_expect(loaded["data"]["simulation_minute"] == simulation.clock.current_minute, "save preserves simulation time")
		var restored: SettlementSimulation = SettlementSimulation.new()
		var restore_result: Dictionary = restored.restore_save_state(loaded["data"]["simulation_minute"], loaded["data"]["state"])
		_expect(restore_result["ok"], "campaign snapshot restores simulation: " + str(restore_result.get("error", "")))
		_expect(restored.events.to_array() == simulation.events.to_array(), "snapshot preserves pending events")
		var continued: Dictionary = restored.advance_time(60)
		_expect(continued["ok"], "JSON-restored simulation continues")
		_expect(restored.resources.get_amount("food") == 110, "JSON-restored event applies resource delta")
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
