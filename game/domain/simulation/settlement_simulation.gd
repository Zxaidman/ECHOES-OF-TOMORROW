class_name SettlementSimulation
extends RefCounted
## Deterministic simulation aggregate. Rendering never drives this class.
const SimulationClock = preload("res://game/domain/simulation/simulation_clock.gd")
const ScheduledEventQueue = preload("res://game/domain/simulation/scheduled_event_queue.gd")
const ResourceLedger = preload("res://game/domain/settlement/resource_ledger.gd")
const RandomStreams = preload("res://game/domain/simulation/random_streams.gd")
const PopulationSimulation = preload("res://game/domain/population/population_simulation.gd")
const RESOURCE_DELTA_EVENT: String = "resource_delta"
const POPULATION_HOURLY_EVENT: String = "population_hourly_tick"
const MAX_MINUTE: int = 2147483647
var clock: SimulationClock
var events: ScheduledEventQueue
var resources: ResourceLedger
var random_streams: RandomStreams
var population: PopulationSimulation
var event_log: Array[Dictionary] = []

func _init(start_minute: int = 480, master_seed: int = 20261108) -> void:
	clock = SimulationClock.new(clampi(start_minute, 0, MAX_MINUTE))
	events = ScheduledEventQueue.new()
	resources = ResourceLedger.new()
	resources.initialize({"food": 120, "wood": 80, "stone": 45, "iron_ore": 12, "tools": 18, "medicine": 6})
	random_streams = RandomStreams.new(master_seed)
	population = PopulationSimulation.new()
	var next_hour: int = (int(start_minute / 60) + 1) * 60
	var next_meal: int = int(start_minute / 1440) * 1440 + 540
	if next_meal <= start_minute:
		next_meal += 1440
	var first_population_tick: int = mini(next_hour, next_meal)
	events.schedule("population-hourly-tick", first_population_tick, 5, POPULATION_HOURLY_EVENT, {}, 60)

func schedule_resource_delta(event_id: String, scheduled_minute: int, priority: int, resource_id: String, amount: int, repeat_interval: int = 0) -> Dictionary:
	if scheduled_minute < clock.current_minute:
		return {"ok": false, "error": "Cannot schedule an event in the past"}
	if not resources.has_resource(resource_id):
		return {"ok": false, "error": "Unknown resource: %s" % resource_id}
	if amount == 0:
		return {"ok": false, "error": "Resource delta cannot be zero"}
	return events.schedule(event_id, scheduled_minute, priority, RESOURCE_DELTA_EVENT, {"resource_id": resource_id, "amount": amount}, repeat_interval)

func advance_time(minutes: int) -> Dictionary:
	if minutes < 0 or clock.current_minute > MAX_MINUTE - minutes:
		return {"ok": false, "error": "Invalid simulation advance"}
	var target_minute: int = clock.current_minute + minutes
	var processed_count: int = 0
	while events.has_due(target_minute):
		var event: Dictionary = events.pop_next_due(target_minute)
		var event_minute: int = int(event["scheduled_minute"])
		if not clock.advance_time(event_minute - clock.current_minute):
			return {"ok": false, "error": "Unable to advance clock to scheduled event"}
		var outcome: Dictionary = _process_event(event)
		outcome["event_id"] = event["id"]
		outcome["scheduled_minute"] = event_minute
		event_log.append(outcome)
		processed_count += 1
		var repeat_interval: int = int(event["repeat_interval"])
		if repeat_interval > 0 and event_minute <= MAX_MINUTE - repeat_interval:
			var repeat_result: Dictionary = events.schedule(str(event["id"]), event_minute + repeat_interval, int(event["priority"]), str(event["type"]), event["payload"], repeat_interval)
			if not repeat_result["ok"]:
				return {"ok": false, "error": str(repeat_result["error"])}
	if not clock.advance_time(target_minute - clock.current_minute):
		return {"ok": false, "error": "Unable to advance simulation clock"}
	return {"ok": true, "processed_events": processed_count, "current_minute": clock.current_minute}

func create_save_state() -> Dictionary:
	return {"resources": resources.to_dictionary(), "scheduled_events": events.to_array(), "next_event_sequence_id": events.get_next_sequence_id(), "random_stream_states": random_streams.to_dictionary(), "population": population.create_save_state()}

func restore_save_state(simulation_minute: int, state: Dictionary) -> Dictionary:
	if simulation_minute < 0 or simulation_minute > MAX_MINUTE or not state.has("resources") or not state["resources"] is Dictionary:
		return {"ok": false, "error": "Invalid simulation save state"}
	if not state.has("scheduled_events") or not state["scheduled_events"] is Array:
		return {"ok": false, "error": "Save is missing scheduled events"}
	if not state.has("next_event_sequence_id") or not _is_integral_number(state["next_event_sequence_id"]):
		return {"ok": false, "error": "Save is missing event sequence state"}
	if not state.has("random_stream_states") or not state["random_stream_states"] is Dictionary:
		return {"ok": false, "error": "Save is missing random stream states"}
	if not state.has("population") or not state["population"] is Dictionary:
		return {"ok": false, "error": "Save is missing population state"}
	var new_resources: ResourceLedger = ResourceLedger.new()
	var resource_result: Dictionary = new_resources.restore(state["resources"])
	if not resource_result["ok"]:
		return resource_result
	var normalized_events: Array = state["scheduled_events"].duplicate(true)
	for event_value: Variant in normalized_events:
		if not event_value is Dictionary:
			return {"ok": false, "error": "Save contains an invalid scheduled event"}
		var event_data: Dictionary = event_value
		if str(event_data.get("type", "")) == RESOURCE_DELTA_EVENT:
			var event_payload: Variant = event_data.get("payload", {})
			if not event_payload is Dictionary or not event_payload.has("amount") or not _is_integral_number(event_payload["amount"]):
				return {"ok": false, "error": "Save contains an invalid resource event amount"}
			event_payload["amount"] = int(event_payload["amount"])
	var new_events: ScheduledEventQueue = ScheduledEventQueue.new()
	var event_result: Dictionary = new_events.restore(normalized_events, int(state["next_event_sequence_id"]))
	if not event_result["ok"]:
		return event_result
	for event: Dictionary in new_events.to_array():
		if int(event["scheduled_minute"]) < simulation_minute:
			return {"ok": false, "error": "Save contains an event scheduled in the past"}
		var payload: Dictionary = event["payload"]
		if str(event["type"]) == RESOURCE_DELTA_EVENT and (not payload.has("resource_id") or not payload["resource_id"] is String or not new_resources.has_resource(str(payload["resource_id"])) or not payload.has("amount") or not _is_integral_number(payload["amount"])):
			return {"ok": false, "error": "Save contains an invalid resource event"}
	var new_population: PopulationSimulation = PopulationSimulation.new()
	var population_result: Dictionary = new_population.restore_save_state(state["population"])
	if not population_result["ok"]:
		return population_result
	var new_random_streams: RandomStreams = RandomStreams.new()
	var rng_result: Dictionary = new_random_streams.restore(state["random_stream_states"])
	if not rng_result["ok"]:
		return rng_result
	resources = new_resources
	events = new_events
	random_streams = new_random_streams
	population = new_population
	clock = SimulationClock.new(simulation_minute)
	event_log.clear()
	return {"ok": true}

func _process_event(event: Dictionary) -> Dictionary:
	if str(event["type"]) == POPULATION_HOURLY_EVENT:
		return population.tick_hour(int(event["scheduled_minute"]), resources)
	if str(event["type"]) != RESOURCE_DELTA_EVENT:
		return {"ok": false, "error": "Unknown event type: %s" % str(event["type"])}
	var payload: Dictionary = event["payload"]
	if not payload.has("resource_id") or not payload.has("amount"):
		return {"ok": false, "error": "Resource event payload is incomplete"}
	if not payload["resource_id"] is String or not _is_integral_number(payload["amount"]):
		return {"ok": false, "error": "Resource event payload has invalid types"}
	var transaction: Dictionary = resources.apply_transaction({str(payload["resource_id"]): int(payload["amount"])})
	return {"ok": bool(transaction["ok"]), "error": str(transaction.get("error", "")), "resource_id": str(payload["resource_id"]), "amount": int(payload["amount"])}

static func _is_integral_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or (typeof(value) == TYPE_FLOAT and value == floor(value))
