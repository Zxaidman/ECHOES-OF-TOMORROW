class_name ScheduledEventQueue
extends RefCounted
## Stable event queue ordered by minute, priority, then insertion sequence.
const MAX_SEQUENCE: int = 2147483647
var _events: Array[Dictionary] = []
var _pending_ids: Dictionary = {}
var _next_sequence_id: int = 1

func schedule(event_id: String, scheduled_minute: int, priority: int, event_type: String, payload: Dictionary, repeat_interval: int = 0) -> Dictionary:
	if event_id.is_empty() or event_type.is_empty():
		return {"ok": false, "error": "Event ID and type are required"}
	if _pending_ids.has(event_id):
		return {"ok": false, "error": "Duplicate pending event ID: %s" % event_id}
	if scheduled_minute < 0 or repeat_interval < 0:
		return {"ok": false, "error": "Event time and repeat interval must be non-negative"}
	if _next_sequence_id > MAX_SEQUENCE:
		return {"ok": false, "error": "Event sequence exhausted"}
	var event: Dictionary = {"id": event_id, "scheduled_minute": scheduled_minute, "priority": priority, "sequence_id": _next_sequence_id, "type": event_type, "payload": payload.duplicate(true), "repeat_interval": repeat_interval}
	_next_sequence_id += 1
	_events.append(event)
	_events.sort_custom(_event_before)
	_pending_ids[event_id] = true
	return {"ok": true, "sequence_id": event["sequence_id"]}

func has_due(target_minute: int) -> bool:
	return not _events.is_empty() and int(_events[0]["scheduled_minute"]) <= target_minute

func pop_next_due(target_minute: int) -> Dictionary:
	if not has_due(target_minute):
		return {}
	var event: Dictionary = _events.pop_front()
	_pending_ids.erase(str(event["id"]))
	return event

func to_array() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event: Dictionary in _events:
		result.append(event.duplicate(true))
	return result

func restore(events: Array, next_sequence_id: int) -> Dictionary:
	if next_sequence_id < 1 or next_sequence_id > MAX_SEQUENCE:
		return {"ok": false, "error": "Invalid next sequence ID"}
	var restored: Array[Dictionary] = []
	var ids: Dictionary = {}
	var maximum_sequence: int = 0
	for value: Variant in events:
		if not value is Dictionary:
			return {"ok": false, "error": "Scheduled event must be an object"}
		var event: Dictionary = value
		if not event.has("id") or not event["id"] is String or str(event["id"]).is_empty():
			return {"ok": false, "error": "Scheduled event has an invalid ID"}
		if ids.has(event["id"]):
			return {"ok": false, "error": "Duplicate scheduled event ID"}
		for required_key: String in ["scheduled_minute", "priority", "sequence_id", "type", "payload", "repeat_interval"]:
			if not event.has(required_key):
				return {"ok": false, "error": "Scheduled event is missing %s" % required_key}
		if not _is_integral_number(event["scheduled_minute"]) or not _is_integral_number(event["priority"]) or not _is_integral_number(event["sequence_id"]) or not _is_integral_number(event["repeat_interval"]):
			return {"ok": false, "error": "Scheduled event has invalid numeric fields"}
		event["scheduled_minute"] = int(event["scheduled_minute"])
		event["priority"] = int(event["priority"])
		event["sequence_id"] = int(event["sequence_id"])
		event["repeat_interval"] = int(event["repeat_interval"])
		if int(event["scheduled_minute"]) < 0 or int(event["sequence_id"]) < 1 or int(event["repeat_interval"]) < 0:
			return {"ok": false, "error": "Scheduled event contains out-of-range values"}
		if not event["type"] is String or str(event["type"]).is_empty() or not event["payload"] is Dictionary:
			return {"ok": false, "error": "Scheduled event has invalid type or payload"}
		ids[event["id"]] = true
		maximum_sequence = maxi(maximum_sequence, int(event["sequence_id"]))
		restored.append(event.duplicate(true))
	if next_sequence_id <= maximum_sequence:
		return {"ok": false, "error": "Next sequence ID must exceed pending event sequence IDs"}
	_events = restored
	_events.sort_custom(_event_before)
	_pending_ids = ids
	_next_sequence_id = next_sequence_id
	return {"ok": true}

func get_next_sequence_id() -> int:
	return _next_sequence_id

func _event_before(left: Dictionary, right: Dictionary) -> bool:
	if int(left["scheduled_minute"]) != int(right["scheduled_minute"]):
		return int(left["scheduled_minute"]) < int(right["scheduled_minute"])
	if int(left["priority"]) != int(right["priority"]):
		return int(left["priority"]) < int(right["priority"])
	return int(left["sequence_id"]) < int(right["sequence_id"])

func _is_integral_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or (typeof(value) == TYPE_FLOAT and value == floor(value))
