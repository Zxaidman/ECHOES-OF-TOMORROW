extends Control
## Responsive dashboard. UI sends simulation commands and renders authoritative state.
const ContentCatalog = preload("res://game/infrastructure/content/content_catalog.gd")
const SettlementSimulation = preload("res://game/domain/simulation/settlement_simulation.gd")
const SaveManager = preload("res://game/infrastructure/persistence/save_manager.gd")
var _simulation: SettlementSimulation
var _resource_values: Dictionary = {}
var _time_label: Label
var _status_label: Label
var _resource_grid: GridContainer

func _ready() -> void:
	_simulation = SettlementSimulation.new()
	var result: Dictionary = ContentCatalog.load_collection("res://content/resources.json", "resources")
	if result["ok"]:
		for definition: Dictionary in result["items"]:
			_resource_values[str(definition["id"])] = definition
	_simulation.schedule_resource_delta("daily-food-consumption", 540, 10, "food", -10, 1440)
	_simulation.schedule_resource_delta("daily-farm-output", 600, 20, "food", 14, 1440)
	_build_screen()
	_refresh_dashboard()

func _build_screen() -> void:
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for pair: Array in [["margin_left", 28], ["margin_top", 24], ["margin_right", 28], ["margin_bottom", 24]]:
		margin.add_theme_constant_override(str(pair[0]), int(pair[1]))
	add_child(margin)
	var page: VBoxContainer = VBoxContainer.new()
	page.add_theme_constant_override("separation", 14)
	margin.add_child(page)
	var title: Label = Label.new()
	title.text = "THE FIRST SPARK"
	title.add_theme_font_size_override("font_size", 30)
	page.add_child(title)
	var subtitle: Label = Label.new()
	subtitle.text = "Rebuild a future from the materials and people of the past."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(subtitle)
	page.add_child(HSeparator.new())
	_time_label = Label.new()
	_time_label.add_theme_font_size_override("font_size", 22)
	page.add_child(_time_label)
	var actions: HFlowContainer = HFlowContainer.new()
	actions.add_theme_constant_override("h_separation", 8)
	actions.add_theme_constant_override("v_separation", 8)
	page.add_child(actions)
	_add_action_button(actions, "Advance 1 hour", 60)
	_add_action_button(actions, "Advance 1 day", 1440)
	var heading: Label = Label.new()
	heading.text = "SETTLEMENT RESOURCES"
	heading.add_theme_font_size_override("font_size", 17)
	page.add_child(heading)
	_resource_grid = GridContainer.new()
	_resource_grid.columns = 3
	_resource_grid.add_theme_constant_override("h_separation", 10)
	_resource_grid.add_theme_constant_override("v_separation", 10)
	page.add_child(_resource_grid)
	var people_heading: Label = Label.new()
	people_heading.text = "PEOPLE TO KNOW"
	people_heading.add_theme_font_size_override("font_size", 17)
	page.add_child(people_heading)
	var people_result: Dictionary = ContentCatalog.load_collection("res://content/npcs.json", "npcs")
	var people_flow: HFlowContainer = HFlowContainer.new()
	people_flow.add_theme_constant_override("h_separation", 8)
	people_flow.add_theme_constant_override("v_separation", 8)
	page.add_child(people_flow)
	if people_result["ok"]:
		for npc: Dictionary in people_result["items"]:
			people_flow.add_child(_make_card(str(npc["name"]), str(npc["role"])))
	else:
		people_flow.add_child(_make_card("Content unavailable", str(people_result["error"])))
	var footer: HFlowContainer = HFlowContainer.new()
	footer.add_theme_constant_override("h_separation", 8)
	page.add_child(footer)
	var save_button: Button = Button.new()
	save_button.text = "Save campaign"
	save_button.pressed.connect(_on_save_pressed)
	footer.add_child(save_button)
	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(_status_label)

func _add_action_button(parent: HFlowContainer, caption: String, minutes: int) -> void:
	var button: Button = Button.new()
	button.text = caption
	button.pressed.connect(_on_advance_pressed.bind(minutes))
	parent.add_child(button)

func _on_advance_pressed(minutes: int) -> void:
	var result: Dictionary = _simulation.advance_time(minutes)
	if result["ok"]:
		_status_label.text = "Time advanced. %d scheduled events processed." % int(result["processed_events"])
	else:
		_status_label.text = "Simulation could not advance: %s" % str(result["error"])
	_refresh_dashboard()

func _on_save_pressed() -> void:
	var manager: SaveManager = SaveManager.new()
	var snapshot: Dictionary = {"campaign_id": "first-spark-local", "simulation_minute": _simulation.clock.current_minute, "state": _simulation.create_save_state()}
	var result: Dictionary = manager.save_snapshot("user://saves/first_spark.json", snapshot)
	_status_label.text = "Campaign saved." if result["ok"] else "Save failed: %s" % str(result["error"])

func _refresh_dashboard() -> void:
	if _time_label == null or _resource_grid == null:
		return
	_time_label.text = "SIMULATION  ·  " + _simulation.clock.format_time()
	for child: Node in _resource_grid.get_children():
		child.queue_free()
	for resource_id: String in _resource_values:
		var definition: Dictionary = _resource_values[resource_id]
		_resource_grid.add_child(_make_card(str(definition["name"]), "%d %s" % [_simulation.resources.get_amount(resource_id), str(definition["unit"])]))

func _make_card(heading: String, value: String) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(165, 76)
	var stack: VBoxContainer = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 4)
	panel.add_child(stack)
	var heading_label: Label = Label.new()
	heading_label.text = heading
	heading_label.add_theme_font_size_override("font_size", 14)
	stack.add_child(heading_label)
	var value_label: Label = Label.new()
	value_label.text = value
	value_label.add_theme_font_size_override("font_size", 18)
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(value_label)
	return panel
