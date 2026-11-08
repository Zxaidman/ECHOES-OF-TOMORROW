extends SceneTree
## Dependency-free headless test runner. Exit code is non-zero on failure.

const SimulationClock = preload("res://game/domain/simulation/simulation_clock.gd")
const ContentCatalog = preload("res://game/infrastructure/content/content_catalog.gd")
const SaveManager = preload("res://game/infrastructure/persistence/save_manager.gd")

var _failures: int = 0
var _assertions: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_clock()
	_test_content_catalog()
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
	var day_clock: SimulationClock = SimulationClock.new(1440)
	_expect(day_clock.format_time() == "Day 2 · 00:00", "clock formats day boundary")


func _test_content_catalog() -> void:
	var resources: Dictionary = ContentCatalog.load_collection("res://content/resources.json", "resources")
	_expect(resources["ok"], "resource content loads")
	_expect(resources["items"].size() == 6, "six starter resources exist")
	var npcs: Dictionary = ContentCatalog.load_collection("res://content/npcs.json", "npcs")
	_expect(npcs["ok"], "NPC content loads")
	_expect(npcs["items"].size() == 5, "five starter NPCs exist")


func _test_save_round_trip() -> void:
	var manager: SaveManager = SaveManager.new()
	var save_path: String = "user://test_campaign.json"
	var snapshot: Dictionary = {
		"campaign_id": "test-campaign",
		"simulation_minute": 125,
		"state": {"food": 99}
	}
	var saved: Dictionary = manager.save_snapshot(save_path, snapshot)
	_expect(saved["ok"], "save snapshot writes")
	var loaded: Dictionary = manager.load_snapshot(save_path)
	_expect(loaded["ok"], "save snapshot loads")
	if loaded["ok"]:
		_expect(loaded["data"]["campaign_id"] == "test-campaign", "save preserves campaign id")
		_expect(loaded["data"]["simulation_minute"] == 125, "save preserves simulation time")
		_expect(loaded["data"]["state"]["food"] == 99, "save preserves state payload")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + ".bak"))


func _expect(condition: bool, message: String) -> void:
	_assertions += 1
	if not condition:
		_failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)
