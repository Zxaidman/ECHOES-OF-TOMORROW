class_name ContentCatalog
extends RefCounted
## Strict JSON boundary for authored game data.

static func load_document(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "Content file not found: %s" % path}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Unable to open content file: %s" % path}
	var raw_text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(raw_text)
	if not parsed is Dictionary:
		return {"ok": false, "error": "Content root must be a JSON object: %s" % path}
	var document: Dictionary = parsed
	if not document.has("schema_version") or not document["schema_version"] is int:
		return {"ok": false, "error": "Missing integer schema_version: %s" % path}
	if int(document["schema_version"]) != 1:
		return {"ok": false, "error": "Unsupported schema_version in %s" % path}
	return {"ok": true, "data": document}


static func load_collection(path: String, collection_key: String) -> Dictionary:
	var result: Dictionary = load_document(path)
	if not result["ok"]:
		return result
	var document: Dictionary = result["data"]
	if not document.has(collection_key) or not document[collection_key] is Array:
		return {"ok": false, "error": "Expected array '%s' in %s" % [collection_key, path]}
	var seen_ids: Dictionary = {}
	for entry: Variant in document[collection_key]:
		if not entry is Dictionary or not entry.has("id") or not entry["id"] is String:
			return {"ok": false, "error": "Every %s entry must have a string id" % collection_key}
		var entry_id: String = entry["id"]
		if entry_id.is_empty() or seen_ids.has(entry_id):
			return {"ok": false, "error": "Empty or duplicate id '%s' in %s" % [entry_id, path]}
		seen_ids[entry_id] = true
	return {"ok": true, "items": document[collection_key]}
