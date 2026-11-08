class_name ResourceLedger
extends RefCounted
## Integer resource ledger. Transactions validate completely before mutation.
const MAX_AMOUNT: int = 2147483647
var _amounts: Dictionary = {}

func initialize(initial_amounts: Dictionary) -> Dictionary:
	var validated: Dictionary = {}
	for resource_id: Variant in initial_amounts.keys():
		if not resource_id is String or str(resource_id).is_empty():
			return {"ok": false, "error": "Resource IDs must be non-empty strings"}
		var amount: Variant = initial_amounts[resource_id]
		if not _is_integral_number(amount) or int(amount) < 0 or int(amount) > MAX_AMOUNT:
			return {"ok": false, "error": "Invalid starting amount for %s" % str(resource_id)}
		validated[resource_id] = int(amount)
	_amounts = validated
	return {"ok": true}

func get_amount(resource_id: String) -> int:
	return int(_amounts.get(resource_id, 0))

func has_resource(resource_id: String) -> bool:
	return _amounts.has(resource_id)

func apply_transaction(changes: Dictionary) -> Dictionary:
	if changes.is_empty():
		return {"ok": false, "error": "Resource transaction cannot be empty"}
	var next_amounts: Dictionary = _amounts.duplicate(true)
	for resource_id: Variant in changes.keys():
		if not resource_id is String or not _amounts.has(resource_id):
			return {"ok": false, "error": "Unknown resource: %s" % str(resource_id)}
		var delta: Variant = changes[resource_id]
		if not delta is int:
			return {"ok": false, "error": "Resource delta must be an integer"}
		var current_amount: int = int(_amounts[resource_id])
		if int(delta) < -current_amount:
			return {"ok": false, "error": "Insufficient %s" % str(resource_id)}
		if int(delta) > MAX_AMOUNT - current_amount:
			return {"ok": false, "error": "Resource amount overflow: %s" % str(resource_id)}
		next_amounts[resource_id] = current_amount + int(delta)
	_amounts = next_amounts
	return {"ok": true, "amounts": _amounts.duplicate(true)}

func to_dictionary() -> Dictionary:
	return _amounts.duplicate(true)

func restore(amounts: Dictionary) -> Dictionary:
	return initialize(amounts)

static func _is_integral_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or (typeof(value) == TYPE_FLOAT and value == floor(value))
