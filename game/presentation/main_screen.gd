extends Control
const ContentCatalog = preload("res://game/infrastructure/content/content_catalog.gd")
const SettlementSimulation = preload("res://game/domain/simulation/settlement_simulation.gd")
const SaveManager = preload("res://game/infrastructure/persistence/save_manager.gd")
const FirstSparkCampaign = preload("res://game/domain/simulation/first_spark_campaign.gd")
var _simulation: SettlementSimulation
var _campaign_progress: FirstSparkCampaign
var _resource_definitions: Array[Dictionary] = []
var _time_label: Label
var _status_label: Label
var _resource_grid: GridContainer
var _objective_container: VBoxContainer
var _population_label: Label
var _timeline_container: VBoxContainer
var _knowledge_container: VBoxContainer
var _facility_container: VBoxContainer
var _invention_container: VBoxContainer
var _dialogue_input: LineEdit
var _dialogue_output: Label
var _selected_npc_id: String = ""
func _ready() -> void:
	_simulation = SettlementSimulation.new()
	_campaign_progress = FirstSparkCampaign.new()
	var resources: Dictionary = ContentCatalog.load_collection("res://content/resources.json", "resources")
	if resources.ok: _resource_definitions.assign(resources.items)
	_simulation.schedule_resource_delta("daily-farm-output", 600, 20, "food", 14, 1440)
	_build_screen()
	_refresh()
func _build_screen() -> void:
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)
	var page: VBoxContainer = VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 12)
	margin.add_child(page)
	var header: HBoxContainer = HBoxContainer.new()
	page.add_child(header)
	var title: Label = Label.new()
	title.text = "First Spark"
	title.add_theme_font_size_override("font_size", 28)
	header.add_child(title)
	header.add_spacer(false)
	_time_label = Label.new()
	_time_label.add_theme_font_size_override("font_size", 18)
	header.add_child(_time_label)
	var controls: HFlowContainer = HFlowContainer.new()
	page.add_child(controls)
	_add_button(controls, "+1 hour", _on_advance.bind(60))
	_add_button(controls, "+1 day", _on_advance.bind(1440))
	_add_button(controls, "Save", _on_save)
	_add_button(controls, "Load", _on_load)
	_resource_grid = GridContainer.new()
	_resource_grid.columns = 6
	page.add_child(_resource_grid)
	get_viewport().size_changed.connect(_update_resource_columns)
	_update_resource_columns()
	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(_status_label)
	var tabs: TabContainer = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_child(tabs)
	var overview: VBoxContainer = _make_tab(tabs, "Overview")
	_objective_container = VBoxContainer.new()
	overview.add_child(_objective_container)
	_population_label = Label.new()
	_population_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overview.add_child(_population_label)
	var people: VBoxContainer = _make_tab(tabs, "People")
	var people_result: Dictionary = ContentCatalog.load_collection("res://content/npcs.json", "npcs")
	if people_result.ok:
		for npc: Dictionary in people_result.items:
			var npc_row: HBoxContainer = _make_row(str(npc.name), str(npc.role))
			_add_button(npc_row, "Select", _on_select_npc.bind(str(npc.id)))
			people.add_child(npc_row)
	else:
		people.add_child(_make_row("Unavailable", str(people_result.error)))
	_dialogue_input = LineEdit.new()
	_dialogue_input.placeholder_text = "Ask a question"
	people.add_child(_dialogue_input)
	_add_button(people, "Send", _on_send_dialogue)
	_dialogue_output = Label.new()
	_dialogue_output.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	people.add_child(_dialogue_output)
	var history: VBoxContainer = _make_tab(tabs, "History")
	_timeline_container = VBoxContainer.new()
	history.add_child(_timeline_container)
	var knowledge: VBoxContainer = _make_tab(tabs, "Knowledge")
	_knowledge_container = VBoxContainer.new()
	knowledge.add_child(_knowledge_container)
	var production: VBoxContainer = _make_tab(tabs, "Production")
	_facility_container = VBoxContainer.new()
	production.add_child(_facility_container)
	production.add_child(HSeparator.new())
	_invention_container = VBoxContainer.new()
	production.add_child(_invention_container)
func _make_tab(tabs: TabContainer, title: String) -> VBoxContainer:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var content: VBoxContainer = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	tabs.add_child(scroll)
	tabs.set_tab_title(tabs.get_tab_count() - 1, title)
	return content
func _add_button(parent: Control, caption: String, callback: Callable) -> Button:
	var button: Button = Button.new()
	button.text = caption
	button.pressed.connect(callback)
	parent.add_child(button)
	return button
func _make_row(primary: String, secondary: String = "") -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	var label: Label = Label.new()
	label.text = primary
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	if not secondary.is_empty():
		var detail: Label = Label.new()
		detail.text = secondary
		detail.modulate = Color(0.72, 0.75, 0.79)
		row.add_child(detail)
	return row
func _refresh() -> void:
	if _time_label == null: return
	_time_label.text = _simulation.clock.format_time()
	_clear(_resource_grid)
	for definition: Dictionary in _resource_definitions:
		_resource_grid.add_child(_resource_card(str(definition.name), _simulation.resources.get_amount(str(definition.id))))
	_population_label.text = _simulation.population.get_overview_text()
	_refresh_objectives()
	_refresh_history()
	_refresh_knowledge()
	_refresh_production()
func _resource_card(name: String, amount: int) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label: Label = Label.new()
	label.text = "%s  %d" % [name, amount]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(label)
	return panel
func _refresh_objectives() -> void:
	_clear(_objective_container)
	var progress: Dictionary = _campaign_progress.get_progress(_simulation)
	for objective: Dictionary in progress.objectives:
		var row: HBoxContainer = HBoxContainer.new()
		var marker: Label = Label.new()
		marker.text = "✓" if bool(objective.complete) else "○"
		marker.custom_minimum_size.x = 20
		row.add_child(marker)
		var title: Label = Label.new()
		title.text = str(objective.title)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(title)
		_objective_container.add_child(row)
	var summary: Label = Label.new()
	summary.text = "Complete" if progress.is_complete else "%d / %d" % [int(progress.completed), int(progress.total)]
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_objective_container.add_child(summary)
func _refresh_history() -> void:
	_clear(_timeline_container)
	for event: Dictionary in _simulation.timeline.get_pending_events():
		var panel: PanelContainer = PanelContainer.new()
		var stack: VBoxContainer = VBoxContainer.new()
		panel.add_child(stack)
		var title: Label = Label.new()
		title.text = str(event.title)
		title.add_theme_font_size_override("font_size", 17)
		stack.add_child(title)
		var description: Label = Label.new()
		description.text = str(event.description)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stack.add_child(description)
		for choice: Dictionary in event.choices:
			var button: Button = Button.new()
			button.text = str(choice.label)
			button.tooltip_text = str(choice.description)
			button.pressed.connect(_on_timeline_choice.bind(str(event.id), str(choice.id)))
			stack.add_child(button)
		_timeline_container.add_child(panel)
	for entry: Dictionary in _simulation.timeline.get_timeline_entries():
		var outcome: String = str(entry.status).capitalize()
		if bool(entry.changed): outcome += " · Changed"
		_timeline_container.add_child(_make_row(str(entry.title), outcome))
func _refresh_knowledge() -> void:
	_clear(_knowledge_container)
	for entry: Dictionary in _simulation.knowledge.get_knowledge_entries(_simulation.population, _simulation.resources):
		var row: HBoxContainer = HBoxContainer.new()
		var name: Label = Label.new()
		name.text = str(entry.name)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name)
		if bool(entry.known):
			var state: Label = Label.new()
			state.text = "Known"
			row.add_child(state)
		else:
			var button: Button = Button.new()
			button.text = "Study"
			button.disabled = not bool(entry.can_study)
			button.tooltip_text = _knowledge_reason(entry)
			button.pressed.connect(_on_study.bind(str(entry.id)))
			row.add_child(button)
		_knowledge_container.add_child(row)
func _knowledge_reason(entry: Dictionary) -> String:
	var reasons: Array[String] = []
	for item: String in entry.missing_knowledge: reasons.append("Requires " + item)
	if not str(entry.missing_skills).is_empty(): reasons.append(str(entry.missing_skills))
	for item: String in entry.missing_resources: reasons.append("Needs " + item)
	return "; ".join(reasons)
func _refresh_production() -> void:
	_clear(_facility_container)
	for entry: Dictionary in _simulation.facilities.get_entries(_simulation.knowledge, _simulation.resources):
		var row: HBoxContainer = HBoxContainer.new()
		var name: Label = Label.new()
		name.text = str(entry.name)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name)
		if bool(entry.built):
			var state: Label = Label.new()
			state.text = "Built"
			row.add_child(state)
		else:
			var button: Button = Button.new()
			button.text = "Build"
			button.disabled = not bool(entry.can_build)
			button.tooltip_text = _facility_reason(entry)
			button.pressed.connect(_on_build.bind(str(entry.id)))
			row.add_child(button)
		_facility_container.add_child(row)
	_clear(_invention_container)
	for entry: Dictionary in _simulation.knowledge.get_invention_entries(_simulation.population, _simulation.resources, _simulation.facilities):
		var row: VBoxContainer = VBoxContainer.new()
		var header: HBoxContainer = HBoxContainer.new()
		row.add_child(header)
		var name: Label = Label.new()
		name.text = str(entry.name)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.add_child(name)
		var state: Label = Label.new()
		state.text = str(entry.status).replace("_", " ").capitalize()
		header.add_child(state)
		var actions: HFlowContainer = HFlowContainer.new()
		row.add_child(actions)
		var item_id: String = str(entry.id)
		if bool(entry.can_prototype): _add_button(actions, "Prototype", _on_prototype.bind(item_id))
		if bool(entry.can_test): _add_button(actions, "Test", _on_test.bind(item_id))
		if bool(entry.can_commission): _add_button(actions, "Commission", _on_commission.bind(item_id))
		if bool(entry.can_produce): _add_button(actions, "Produce", _on_produce.bind(item_id))
		var reason: String = _invention_reason(entry)
		if not reason.is_empty(): row.tooltip_text = reason
		_invention_container.add_child(row)
func _facility_reason(entry: Dictionary) -> String:
	var reasons: Array[String] = []
	for item: String in entry.missing_knowledge: reasons.append("Requires " + item)
	for item: String in entry.missing_resources: reasons.append("Needs " + item)
	return "; ".join(reasons)
func _invention_reason(entry: Dictionary) -> String:
	var reasons: Array[String] = []
	for item: String in entry.missing_knowledge: reasons.append("Requires " + item)
	for item: String in entry.missing_inventions: reasons.append("Requires " + item)
	if not str(entry.missing_skills).is_empty(): reasons.append(str(entry.missing_skills))
	for item: String in entry.missing_resources: reasons.append("Needs " + item)
	if not str(entry.missing_facility).is_empty(): reasons.append("Requires " + str(entry.missing_facility))
	if not str(entry.last_failure).is_empty(): reasons.append(str(entry.last_failure))
	return "; ".join(reasons)
func _clear(container: Node) -> void:
	for child: Node in container.get_children():
		container.remove_child(child)
		child.queue_free()
func _on_advance(minutes: int) -> void:
	var result: Dictionary = _simulation.advance_time(minutes)
	_set_status("Advanced." if result.ok else str(result.error))
	_refresh()
func _on_save() -> void:
	var snapshot: Dictionary = {"campaign_id": "first-spark-local", "simulation_minute": _simulation.clock.current_minute, "state": _simulation.create_save_state()}
	var result: Dictionary = SaveManager.new().save_snapshot("user://saves/first_spark.json", snapshot)
	_set_status("Saved." if result.ok else str(result.error))
func _on_load() -> void:
	var loaded: Dictionary = SaveManager.new().load_snapshot("user://saves/first_spark.json")
	if not loaded.ok: _set_status(str(loaded.error)); return
	if str(loaded.data.get("campaign_id", "")) != "first-spark-local": _set_status("Save belongs to another campaign."); return
	var restored: SettlementSimulation = SettlementSimulation.new()
	var result: Dictionary = restored.restore_save_state(int(loaded.data.simulation_minute), loaded.data.state)
	if not result.ok: _set_status(str(result.error)); return
	_simulation = restored
	_set_status("Recovered previous save. Save again to replace the damaged file." if bool(loaded.get("recovered_from_backup", false)) else "Loaded.")
	_refresh()
func _update_resource_columns() -> void:
	if _resource_grid == null:
		return
	_resource_grid.columns = 3 if get_viewport_rect().size.x < 900.0 else 6

func _on_select_npc(npc_id: String) -> void:
	_selected_npc_id = npc_id
	var npc: Dictionary = _simulation.population.get_npc(npc_id)
	_dialogue_output.text = str(npc.get("name", npc_id))

func _on_send_dialogue() -> void:
	if _selected_npc_id.is_empty():
		_dialogue_output.text = "Select a person."
		return
	var result: Dictionary = _simulation.request_npc_dialogue(_selected_npc_id, _dialogue_input.text)
	if not result.ok:
		_dialogue_output.text = str(result.error)
		return
	_dialogue_output.text = str(result.proposal.dialogue_text)
	_dialogue_input.clear()

func _on_timeline_choice(event_id: String, choice_id: String) -> void:
	var result: Dictionary = _simulation.resolve_historical_choice(event_id, choice_id)
	_set_status("History updated." if result.ok else str(result.error))
	_refresh()
func _on_study(knowledge_id: String) -> void:
	var result: Dictionary = _simulation.knowledge.study_knowledge(knowledge_id, _simulation.population, _simulation.resources)
	_set_status("Knowledge learned." if result.ok else str(result.error))
	_refresh()
func _on_build(facility_id: String) -> void:
	var result: Dictionary = _simulation.build_facility(facility_id)
	_set_status("Built." if result.ok else str(result.error))
	_refresh()
func _on_prototype(invention_id: String) -> void:
	var result: Dictionary = _simulation.knowledge.attempt_prototype(invention_id, _simulation.population, _simulation.resources)
	_set_status("Prototype built." if result.ok else str(result.error))
	_refresh()
func _on_test(invention_id: String) -> void:
	var result: Dictionary = _simulation.knowledge.test_prototype(invention_id, _simulation.population)
	if not result.ok: _set_status(str(result.error))
	elif result.validated: _set_status("Validated.")
	else: _set_status(str(result.reason))
	_refresh()
func _on_commission(invention_id: String) -> void:
	var result: Dictionary = _simulation.knowledge.commission_production(invention_id)
	_set_status("Production ready." if result.ok else str(result.error))
	_refresh()
func _on_produce(invention_id: String) -> void:
	var result: Dictionary = _simulation.produce_invention(invention_id)
	_set_status("Produced." if result.ok else str(result.error))
	_refresh()
func _set_status(message: String) -> void:
	_status_label.text = message
