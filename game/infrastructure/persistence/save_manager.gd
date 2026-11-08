class_name SaveManager
extends RefCounted
## Versioned JSON snapshot persistence with verified temporary writes and a previous-good backup.

const SAVE_SCHEMA_VERSION: int = 1


func save_snapshot(path: String, snapshot: Dictionary) -> Dictionary:
	if not snapshot.has("campaign_id") or not snapshot["campaign_id"] is String or str(snapshot["campaign_id"]).is_empty():
		return {"ok": false, "error": "Save requires a non-empty string campaign_id"}
	if not snapshot.has("simulation_minute") or not _is_integral_number(snapshot["simulation_minute"]):
		return {"ok": false, "error": "Save requires an integer simulation_minute"}
	if int(snapshot["simulation_minute"]) < 0:
		return {"ok": false, "error": "simulation_minute cannot be negative"}
	if not snapshot.get("state", {}) is Dictionary:
		return {"ok": false, "error": "Save state must be a dictionary"}

	var directory_path: String = ProjectSettings.globalize_path(path.get_base_dir())
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(directory_path)
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		return {"ok": false, "error": "Unable to create save directory"}

	var dto: Dictionary = {
		"schema_version": SAVE_SCHEMA_VERSION,
		"game_version": str(ProjectSettings.get_setting("application/config/version", "0.3.0")),
		"campaign_id": snapshot["campaign_id"],
		"simulation_minute": int(snapshot["simulation_minute"]),
		"state": snapshot.get("state", {})
	}
	var temporary_path: String = path + ".tmp"
	var backup_path: String = path + ".bak"
	var absolute_path: String = ProjectSettings.globalize_path(path)
	var absolute_temp: String = ProjectSettings.globalize_path(temporary_path)
	var absolute_backup: String = ProjectSettings.globalize_path(backup_path)

	var temporary_file: FileAccess = FileAccess.open(temporary_path, FileAccess.WRITE)
	if temporary_file == null:
		return {"ok": false, "error": "Unable to create temporary save"}
	temporary_file.store_string(JSON.stringify(dto, "\t"))
	temporary_file.flush()
	var write_error: Error = temporary_file.get_error()
	temporary_file.close()
	if write_error != OK:
		DirAccess.remove_absolute(absolute_temp)
		return {"ok": false, "error": "Failed while writing temporary save"}

	var verification_file: FileAccess = FileAccess.open(temporary_path, FileAccess.READ)
	if verification_file == null:
		DirAccess.remove_absolute(absolute_temp)
		return {"ok": false, "error": "Unable to verify temporary save"}
	var verification_data: Variant = JSON.parse_string(verification_file.get_as_text())
	verification_file.close()
	if not verification_data is Dictionary or str(verification_data.get("campaign_id", "")) != str(dto["campaign_id"]):
		DirAccess.remove_absolute(absolute_temp)
		return {"ok": false, "error": "Temporary save failed verification"}

	var had_previous_save: bool = FileAccess.file_exists(path)
	if had_previous_save:
		if FileAccess.file_exists(backup_path):
			var remove_backup_error: Error = DirAccess.remove_absolute(absolute_backup)
			if remove_backup_error != OK:
				DirAccess.remove_absolute(absolute_temp)
				return {"ok": false, "error": "Unable to rotate previous backup"}
		var backup_error: Error = DirAccess.rename_absolute(absolute_path, absolute_backup)
		if backup_error != OK:
			DirAccess.remove_absolute(absolute_temp)
			return {"ok": false, "error": "Unable to preserve previous save"}

	var replace_error: Error = DirAccess.rename_absolute(absolute_temp, absolute_path)
	if replace_error != OK:
		if had_previous_save:
			DirAccess.rename_absolute(absolute_backup, absolute_path)
		return {"ok": false, "error": "Unable to replace active save"}
	return {"ok": true, "backup_created": had_previous_save}


func load_snapshot(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "Save file does not exist"}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Unable to open save file"}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		return {"ok": false, "error": "Save root must be a JSON object"}
	var dto: Dictionary = parsed
	if not _is_integral_number(dto.get("schema_version", -1)) or int(dto["schema_version"]) != SAVE_SCHEMA_VERSION:
		return {"ok": false, "error": "Unsupported save schema version"}
	if not dto.has("campaign_id") or not dto.has("simulation_minute") or not dto.has("state"):
		return {"ok": false, "error": "Save is missing required fields"}
	if not dto["campaign_id"] is String or not _is_integral_number(dto["simulation_minute"]) or not dto["state"] is Dictionary:
		return {"ok": false, "error": "Save contains invalid field types"}
	if int(dto["simulation_minute"]) < 0:
		return {"ok": false, "error": "Save contains a negative simulation minute"}
	dto["schema_version"] = int(dto["schema_version"])
	dto["simulation_minute"] = int(dto["simulation_minute"])
	return {"ok": true, "data": dto}


static func _is_integral_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or (typeof(value) == TYPE_FLOAT and value == floor(value))
