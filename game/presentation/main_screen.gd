extends Control
## Responsive dashboard. UI sends simulation commands and renders authoritative state.
const ContentCatalog = preload("res://game/infrastructure/content/content_catalog.gd")
const SettlementSimulation = preload("res://game/domain/simulation/settlement_simulation.gd")
const SaveManager = preload("res://game/infrastructure/persistence/save_manager.gd")
const FirstSparkCampaign = preload("res://game/domain/simulation/first_spark_campaign.gd")
var _simulation: SettlementSimulation
var _resource_values: Dictionary = {}
var _time_label: Label
var _status_label: Label
var _resource_grid: GridContainer
var _population_summary_label: Label
var _knowledge_container: VBoxContainer
var _invention_container: VBoxContainer
var _timeline_container: VBoxContainer
var _objective_container: VBoxContainer
var _campaign_progress: FirstSparkCampaign

func _ready() -> void:
	_simulation = SettlementSimulation.new()
	_campaign_progress = FirstSparkCampaign.new()
	var result: Dictionary = ContentCatalog.load_collection("res://content/resources.json", "resources")
	if result["ok"]:
		for definition: Dictionary in result["items"]:
			_resource_values[str(definition["id"])] = definition
	_simulation.schedule_resource_delta("daily-farm-output", 600, 20, "food", 14, 1440)
	_build_screen()
	_refresh_dashboard()

func _build_screen() -> void:
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for pair: Array in [["margin_left", 28], ["margin_top", 24], ["margin_right", 28], ["margin_bottom", 24]]:
		margin.add_theme_constant_override(str(pair[0]), int(pair[1]))
	add_child(margin)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	var page: VBoxContainer = VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(page)
	page.add_theme_constant_override("separation", 14)
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
	var objective_heading: Label = Label.new()
	objective_heading.text = "FIRST SPARK · CAMPAIGN OBJECTIVES"
	objective_heading.add_theme_font_size_override("font_size", 19)
	page.add_child(objective_heading)
	_objective_container = VBoxContainer.new()
	_objective_container.add_theme_constant_override("separation", 6)
	page.add_child(_objective_container)
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
	_population_summary_label = Label.new()
	_population_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(_population_summary_label)
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
	var timeline_heading: Label = Label.new()
	timeline_heading.text = "HISTORICAL TIMELINE"
	timeline_heading.add_theme_font_size_override("font_size",19)
	page.add_child(timeline_heading)
	_timeline_container = VBoxContainer.new()
	_timeline_container.add_theme_constant_override("separation",8)
	page.add_child(_timeline_container)
	var knowledge_heading: Label = Label.new()
	knowledge_heading.text = "FUTURE KNOWLEDGE"
	knowledge_heading.add_theme_font_size_override("font_size", 19)
	page.add_child(knowledge_heading)
	_knowledge_container = VBoxContainer.new()
	_knowledge_container.add_theme_constant_override("separation", 8)
	page.add_child(_knowledge_container)
	var invention_heading: Label = Label.new()
	invention_heading.text = "INVENTION WORKSHOP"
	invention_heading.add_theme_font_size_override("font_size", 19)
	page.add_child(invention_heading)
	_invention_container = VBoxContainer.new()
	_invention_container.add_theme_constant_override("separation", 8)
	page.add_child(_invention_container)
	var footer: HFlowContainer = HFlowContainer.new()
	footer.add_theme_constant_override("h_separation", 8)
	page.add_child(footer)
	var save_button: Button = Button.new()
	save_button.text = "Save campaign"
	save_button.pressed.connect(_on_save_pressed)
	footer.add_child(save_button)
	var load_button: Button = Button.new()
	load_button.text = "Load campaign"
	load_button.pressed.connect(_on_load_pressed)
	footer.add_child(load_button)
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

func _on_load_pressed() -> void:
	var manager: SaveManager = SaveManager.new()
	var loaded: Dictionary = manager.load_snapshot("user://saves/first_spark.json")
	if not loaded.ok:
		_status_label.text = "Load failed: %s" % str(loaded.error)
		return
	if str(loaded.data.get("campaign_id", "")) != "first-spark-local":
		_status_label.text = "Load failed: save belongs to another campaign."
		return
	var restored: SettlementSimulation = SettlementSimulation.new()
	var restore_result: Dictionary = restored.restore_save_state(int(loaded.data.simulation_minute), loaded.data.state)
	if not restore_result.ok:
		_status_label.text = "Load failed: %s" % str(restore_result.error)
		return
	_simulation = restored
	_status_label.text = "Campaign loaded."
	_refresh_dashboard()

func _refresh_dashboard() -> void:
	if _time_label == null or _resource_grid == null:
		return
	_time_label.text = "SIMULATION  ·  " + _simulation.clock.format_time()
	for child: Node in _resource_grid.get_children():
		_resource_grid.remove_child(child)
		child.queue_free()
	if _population_summary_label != null:
		_population_summary_label.text = _simulation.population.get_overview_text()
	_refresh_campaign_objectives()
	_refresh_progression()
	_refresh_timeline()
	for resource_id: String in _resource_values:
		var definition: Dictionary = _resource_values[resource_id]
		_resource_grid.add_child(_make_card(str(definition["name"]), "%d %s" % [_simulation.resources.get_amount(resource_id), str(definition["unit"])]))

func _refresh_campaign_objectives() -> void:
	if _objective_container == null or _campaign_progress == null:
		return
	_clear_container(_objective_container)
	var progress: Dictionary = _campaign_progress.get_progress(_simulation)
	for objective: Dictionary in progress.objectives:
		var line: Label = Label.new()
		var marker: String = "[DONE]" if bool(objective.complete) else "[TODO]"
		line.text = "%s  %s — %s" % [marker, str(objective.title), str(objective.description)]
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_objective_container.add_child(line)
	var summary: Label = Label.new()
	summary.text = "Campaign complete — The First Spark has been established." if progress.is_complete else "Progress: %d / %d objectives" % [int(progress.completed), int(progress.total)]
	summary.add_theme_font_size_override("font_size", 15)
	_objective_container.add_child(summary)

func _refresh_timeline() -> void:
	if _timeline_container == null:
		return
	_clear_container(_timeline_container)
	for event: Dictionary in _simulation.timeline.get_pending_events():
		var panel: PanelContainer = PanelContainer.new()
		var stack: VBoxContainer = VBoxContainer.new()
		stack.add_theme_constant_override("separation",6)
		panel.add_child(stack)
		var heading: Label = Label.new()
		heading.text = "DECISION REQUIRED  ·  " + str(event.title)
		heading.add_theme_font_size_override("font_size",16)
		stack.add_child(heading)
		var description: Label = Label.new()
		description.text = str(event.description)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stack.add_child(description)
		for choice: Dictionary in event.choices:
			var choice_button: Button = Button.new()
			choice_button.text = str(choice.label)
			choice_button.tooltip_text = str(choice.description)
			choice_button.pressed.connect(_on_timeline_choice_pressed.bind(str(event.id),str(choice.id)))
			stack.add_child(choice_button)
		_timeline_container.add_child(panel)
	for entry: Dictionary in _simulation.timeline.get_timeline_entries():
		var line: Label = Label.new()
		var timing: String = "Original: Day %d" % (int(entry.original_minute) / 1440 + 1) if int(entry.original_minute) >= 0 else "Original: not scheduled"
		if int(entry.resolution_minute) >= 0:
			timing += "  ·  Resolved: Day %d" % (int(entry.resolution_minute) / 1440 + 1)
		var outcome: String = str(entry.status).replace("_"," ").to_upper()
		if bool(entry.changed):
			outcome += "  ·  HISTORY ALTERED"
		var outcome_detail: String = ""
		if not str(entry.selected_choice_label).is_empty():
			outcome_detail = "  ·  Expected: %s  ·  Chosen: %s" % [str(entry.baseline_choice_label),str(entry.selected_choice_label)]
		line.text = "%s  ·  %s  ·  %s%s" % [str(entry.title),outcome,timing,outcome_detail]
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_timeline_container.add_child(line)

func _on_timeline_choice_pressed(event_id: String, choice_id: String) -> void:
	var result: Dictionary = _simulation.resolve_historical_choice(event_id,choice_id)
	_status_label.text = "History updated: %s." % str(result.event.title) if result.ok else "Choice unavailable: %s" % str(result.error)
	_refresh_dashboard()

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

func _refresh_progression() -> void:
	if _knowledge_container == null or _invention_container == null:
		return
	_clear_container(_knowledge_container)
	_clear_container(_invention_container)
	for entry: Dictionary in _simulation.knowledge.get_knowledge_entries(_simulation.population,_simulation.resources):
		var row: PanelContainer = PanelContainer.new()
		var line: HBoxContainer = HBoxContainer.new()
		row.add_child(line)
		var details: VBoxContainer = VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(details)
		var name_label: Label = Label.new()
		name_label.text = str(entry.name) + ("  ·  UNDERSTOOD" if entry.known else "  ·  NOT YET UNDERSTOOD")
		name_label.add_theme_font_size_override("font_size",15)
		details.add_child(name_label)
		var description: Label = Label.new()
		description.text = str(entry.description)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details.add_child(description)
		if not entry.known:
			var missing: Array[String] = []
			for item: String in entry.missing_knowledge:
				missing.append("knowledge: " + item)
			if not str(entry.missing_skills).is_empty():
				missing.append(str(entry.missing_skills))
			for item: String in entry.missing_resources:
				missing.append("resources: " + item)
			var requirement_label: Label = Label.new()
			requirement_label.text = "Requirements: " + ("; ".join(PackedStringArray(missing)) if not missing.is_empty() else "ready to study")
			requirement_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			details.add_child(requirement_label)
			var study_button: Button = Button.new()
			study_button.text = "Study"
			study_button.disabled = not bool(entry.can_study)
			study_button.pressed.connect(_on_study_pressed.bind(str(entry.id)))
			line.add_child(study_button)
		_knowledge_container.add_child(row)
	for entry: Dictionary in _simulation.knowledge.get_invention_entries(_simulation.population,_simulation.resources):
		var row: PanelContainer = PanelContainer.new()
		var line: HBoxContainer = HBoxContainer.new()
		row.add_child(line)
		var details: VBoxContainer = VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(details)
		var name_label: Label = Label.new()
		name_label.text = "%s  ·  %s  ·  %s" % [str(entry.name),str(entry.category),str(entry.status).to_upper()]
		name_label.add_theme_font_size_override("font_size",15)
		details.add_child(name_label)
		var description: Label = Label.new()
		description.text = str(entry.description)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details.add_child(description)
		var missing: Array[String] = []
		for item: String in entry.missing_knowledge:
			missing.append("knowledge: " + item)
		for item: String in entry.missing_inventions:
			missing.append("invention: " + item)
		if not str(entry.missing_skills).is_empty():
			missing.append(str(entry.missing_skills))
		for item: String in entry.missing_resources:
			missing.append("prototype materials: " + item)
		if not missing.is_empty():
			var requirements: Label = Label.new()
			requirements.text = "Missing: " + "; ".join(missing)
			requirements.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			details.add_child(requirements)
		if not str(entry.last_failure).is_empty():
			var failure: Label = Label.new()
			failure.text = "Last test: " + str(entry.last_failure)
			failure.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			details.add_child(failure)
		var actions: VBoxContainer = VBoxContainer.new()
		line.add_child(actions)
		if bool(entry.can_prototype):
			_add_progress_button(actions,"Build prototype",_on_prototype_pressed.bind(str(entry.id)))
		if bool(entry.can_test):
			_add_progress_button(actions,"Test prototype",_on_test_pressed.bind(str(entry.id)))
		if bool(entry.can_commission):
			_add_progress_button(actions,"Commission production",_on_commission_pressed.bind(str(entry.id)))
		if bool(entry.can_produce):
			_add_progress_button(actions,"Produce",_on_produce_pressed.bind(str(entry.id)))
		_invention_container.add_child(row)

func _clear_container(container: VBoxContainer) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _add_progress_button(parent: VBoxContainer, caption: String, callback: Callable) -> void:
	var button: Button = Button.new()
	button.text = caption
	button.pressed.connect(callback)
	parent.add_child(button)

func _on_study_pressed(knowledge_id: String) -> void:
	var result: Dictionary = _simulation.knowledge.study_knowledge(knowledge_id,_simulation.population,_simulation.resources)
	_status_label.text = "Knowledge recorded." if result.ok else "Study blocked: %s" % str(result.error)
	_refresh_dashboard()

func _on_prototype_pressed(invention_id: String) -> void:
	var result: Dictionary = _simulation.knowledge.attempt_prototype(invention_id,_simulation.population,_simulation.resources)
	_status_label.text = "Prototype built." if result.ok else "Prototype blocked: %s" % str(result.error)
	_refresh_dashboard()

func _on_test_pressed(invention_id: String) -> void:
	var result: Dictionary = _simulation.knowledge.test_prototype(invention_id,_simulation.population)
	if not result.ok:
		_status_label.text = "Test unavailable: %s" % str(result.error)
	elif result.validated:
		_status_label.text = "Validation passed. Score: %d." % int(result.score)
	else:
		_status_label.text = "Validation failed: %s." % str(result.reason)
	_refresh_dashboard()

func _on_commission_pressed(invention_id: String) -> void:
	var result: Dictionary = _simulation.knowledge.commission_production(invention_id)
	_status_label.text = "Production commissioned." if result.ok else "Commission blocked: %s" % str(result.error)
	_refresh_dashboard()

func _on_produce_pressed(invention_id: String) -> void:
	var result: Dictionary = _simulation.knowledge.produce(invention_id,_simulation.resources)
	_status_label.text = "Production complete." if result.ok else "Production failed: %s" % str(result.error)
	_refresh_dashboard()
