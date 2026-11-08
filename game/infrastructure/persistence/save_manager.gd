class_name SaveManager
extends RefCounted
## Versioned JSON snapshots with verified temporary writes and backup recovery.
const SAVE_SCHEMA_VERSION: int = 1
func save_snapshot(path: String, snapshot: Dictionary) -> Dictionary:
	if not snapshot.has("campaign_id") or not snapshot["campaign_id"] is String or str(snapshot["campaign_id"]).strip_edges().is_empty():
		return {"ok": false, "error": "Save requires a non-empty campaign_id"}
	if not snapshot.has("simulation_minute") or not _is_integral_number(snapshot["simulation_minute"]) or int(snapshot["simulation_minute"]) < 0:
		return {"ok": false, "error": "Save requires a non-negative integer simulation_minute"}
	if not snapshot.get("state", null) is Dictionary:
		return {"ok": false, "error": "Save state must be a dictionary"}
	var directory_path: String = ProjectSettings.globalize_path(path.get_base_dir())
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(directory_path)
	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		return {"ok": false, "error": "Unable to create save directory"}
	var dto: Dictionary = {"schema_version": SAVE_SCHEMA_VERSION, "game_version": str(ProjectSettings.get_setting("application/config/version", "1.0.0")), "campaign_id": str(snapshot["campaign_id"]).strip_edges(), "simulation_minute": int(snapshot["simulation_minute"]), "state": snapshot["state"]}
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
	var verification: Dictionary = _read_snapshot_file(temporary_path)
	if not verification.ok or verification.data.campaign_id != dto.campaign_id or verification.data.simulation_minute != dto.simulation_minute:
		DirAccess.remove_absolute(absolute_temp)
		return {"ok": false, "error": "Temporary save failed verification"}
	var had_previous_save: bool = FileAccess.file_exists(path)
	var previous_save: Dictionary = _read_snapshot_file(path) if had_previous_save else {"ok": false}
	if had_previous_save and previous_save.ok:
		if FileAccess.file_exists(backup_path):
			var remove_backup_error: Error = DirAccess.remove_absolute(absolute_backup)
			if remove_backup_error != OK:
				DirAccess.remove_absolute(absolute_temp)
				return {"ok": false, "error": "Unable to rotate previous backup"}
		var backup_error: Error = DirAccess.rename_absolute(absolute_path, absolute_backup)
		if backup_error != OK:
			DirAccess.remove_absolute(absolute_temp)
			return {"ok": false, "error": "Unable to preserve previous save"}
	elif had_previous_save:
		# The active file is corrupt. Keep any verified backup untouched.
		var remove_invalid_error: Error = DirAccess.remove_absolute(absolute_path)
		if remove_invalid_error != OK:
			DirAccess.remove_absolute(absolute_temp)
			return {"ok": false, "error": "Unable to replace invalid active save"}
	var replace_error: Error = DirAccess.rename_absolute(absolute_temp, absolute_path)
	if replace_error != OK:
		if had_previous_save:
			DirAccess.rename_absolute(absolute_backup, absolute_path)
		return {"ok": false, "error": "Unable to replace active save"}
	return {"ok": true, "backup_created": FileAccess.file_exists(backup_path)}
func load_snapshot(path: String) -> Dictionary:
	var primary: Dictionary = _read_snapshot_file(path)
	if primary.ok:
		return {"ok": true, "data": primary.data, "recovered_from_backup": false}
	var backup: Dictionary = _read_snapshot_file(path + ".bak")
	if backup.ok:
		return {"ok": true, "data": backup.data, "recovered_from_backup": true, "warning": "The active save could not be read. The previous verified save was loaded."}
	return {"ok": false, "error": str(primary.error) + "; backup unavailable: " + str(backup.error)}
func _read_snapshot_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "Save file does not exist"}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Unable to open save file"}
	var parser: JSON = JSON.new()
	var parse_error: Error = parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		return {"ok": false, "error": "Save JSON is invalid: %s" % parser.get_error_message()}
	var parsed: Variant = parser.data
	if not parsed is Dictionary:
		return {"ok": false, "error": "Save root must be a JSON object"}
	var dto: Dictionary = parsed
	if not _is_integral_number(dto.get("schema_version", -1)) or int(dto["schema_version"]) != SAVE_SCHEMA_VERSION:
		return {"ok": false, "error": "Unsupported save schema version"}
	if not dto.has("campaign_id") or not dto.has("simulation_minute") or not dto.has("state"):
		return {"ok": false, "error": "Save is missing required fields"}
	if not dto["campaign_id"] is String or str(dto["campaign_id"]).strip_edges().is_empty() or not _is_integral_number(dto["simulation_minute"]) or not dto["state"] is Dictionary:
		return {"ok": false, "error": "Save contains invalid field types"}
	if int(dto["simulation_minute"]) < 0:
		return {"ok": false, "error": "Save contains a negative simulation minute"}
	if dto.has("game_version") and not dto["game_version"] is String:
		return {"ok": false, "error": "Save contains an invalid game version"}
	dto["schema_version"] = int(dto["schema_version"])
	dto["simulation_minute"] = int(dto["simulation_minute"])
	return {"ok": true, "data": dto}
static func _is_integral_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or (typeof(value) == TYPE_FLOAT and value == floor(value))
