extends Control

const ContentCatalog = preload("res://game/infrastructure/content/content_catalog.gd")
const SettlementSimulation = preload("res://game/domain/simulation/settlement_simulation.gd")
const SaveManager = preload("res://game/infrastructure/persistence/save_manager.gd")
const FirstSparkCampaign = preload("res://game/domain/simulation/first_spark_campaign.gd")
const SettlementWorld = preload("res://game/presentation/settlement_world.gd")

const RESOURCE_ORDER: Array[String] = ["food", "wood", "stone", "tools"]
const RESOURCE_LABELS: Dictionary = {
	"food": "FOOD", "wood": "WOOD", "stone": "STONE", "tools": "TOOLS"
}

var _simulation: SettlementSimulation
var _campaign_progress: FirstSparkCampaign
var _world: SettlementWorld
var _resource_labels: Dictionary = {}
var _side_panel: VBoxContainer
var _panel_title: Label
var _panel_body: Label
var _panel_content: VBoxContainer
var _status_label: Label
var _dialogue_input: LineEdit
var _dialogue_output: Label
var _selected_npc_id: String = ""
var _selected_type: String = "building"
var _selected_id: String = "farmstead"
var _active_view: String = "village"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_simulation = SettlementSimulation.new()
	_campaign_progress = FirstSparkCampaign.new()
	_simulation.schedule_resource_delta("daily-farm-output", 600, 20, "food", 14, 1440)
	_world = SettlementWorld.new()
	_world.name = "SettlementWorld"
	_world.entity_selected.connect(_on_world_entity_selected)
	add_child(_world)
	_build_interface()
	_refresh()

func _build_interface() -> void:
	_build_top_hud()
	_build_side_panel()
	_build_bottom_navigation()
	_build_status_toast()

func _build_top_hud() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left = 16.0
	panel.offset_top = 14.0
	panel.offset_right = -16.0
	panel.offset_bottom = 102.0
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#292c27"), 0.94, 14))
	add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	panel.add_child(row)

	var brand := VBoxContainer.new()
	brand.custom_minimum_size.x = 150.0
	row.add_child(brand)
	var title := Label.new()
	title.text = "ECHOES OF TOMORROW"
	title.add_theme_color_override("font_color", Color("#f0dfbd"))
	title.add_theme_font_size_override("font_size", 16)
	brand.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "FIRST SPARK  ·  SETTLEMENT"
	subtitle.add_theme_color_override("font_color", Color("#b9aa8c"))
	subtitle.add_theme_font_size_override("font_size", 10)
	brand.add_child(subtitle)

	var separator := VSeparator.new()
	row.add_child(separator)
	for resource_id: String in RESOURCE_ORDER:
		var resource_stack := VBoxContainer.new()
		resource_stack.custom_minimum_size.x = 72.0
		resource_stack.add_theme_constant_override("separation", 1)
		row.add_child(resource_stack)
		var name_label := Label.new()
		name_label.text = RESOURCE_LABELS[resource_id]
		name_label.add_theme_color_override("font_color", Color("#b7a98b"))
		name_label.add_theme_font_size_override("font_size", 10)
		resource_stack.add_child(name_label)
		var amount_label := Label.new()
		amount_label.text = "—"
		amount_label.add_theme_color_override("font_color", Color("#f2e5ca"))
		amount_label.add_theme_font_size_override("font_size", 20)
		resource_stack.add_child(amount_label)
		_resource_labels[resource_id] = amount_label

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var time_stack := VBoxContainer.new()
	time_stack.add_theme_constant_override("separation", 1)
	row.add_child(time_stack)
	var time_caption := Label.new()
	time_caption.text = "SETTLEMENT TIME"
	time_caption.add_theme_color_override("font_color", Color("#b7a98b"))
	time_caption.add_theme_font_size_override("font_size", 10)
	time_stack.add_child(time_caption)
	var time_label := Label.new()
	time_label.name = "TimeLabel"
	time_label.text = "08:00"
	time_label.add_theme_color_override("font_color", Color("#f2e5ca"))
	time_label.add_theme_font_size_override("font_size", 20)
	time_stack.add_child(time_label)

	var controls := VBoxContainer.new()
	controls.add_theme_constant_override("separation", 4)
	row.add_child(controls)
	_add_button(controls, "＋ 1 HOUR", _on_advance.bind(60), true)
	_add_button(controls, "＋ 1 DAY", _on_advance.bind(1440), false)

func _build_side_panel() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	panel.offset_left = -350.0
	panel.offset_top = 120.0
	panel.offset_right = -16.0
	panel.offset_bottom = -108.0
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#292c27"), 0.94, 14))
	add_child(panel)

	_side_panel = VBoxContainer.new()
	_side_panel.add_theme_constant_override("separation", 10)
	panel.add_child(_side_panel)

	var heading := HBoxContainer.new()
	_side_panel.add_child(heading)
	_panel_title = Label.new()
	_panel_title.text = "FARMSTEAD"
	_panel_title.add_theme_color_override("font_color", Color("#f0dfbd"))
	_panel_title.add_theme_font_size_override("font_size", 20)
	_panel_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(_panel_title)
	var close_button := _add_button(heading, "×", _on_clear_selection, false)
	close_button.custom_minimum_size = Vector2(34.0, 30.0)

	_panel_body = Label.new()
	_panel_body.text = "Your settlement is beginning to take shape."
	_panel_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel_body.add_theme_color_override("font_color", Color("#c9bea7"))
	_side_panel.add_child(_panel_body)

	var rule := HSeparator.new()
	_side_panel.add_child(rule)
	var content_scroll := ScrollContainer.new()
	content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_side_panel.add_child(content_scroll)
	_panel_content = VBoxContainer.new()
	_panel_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel_content.add_theme_constant_override("separation", 7)
	content_scroll.add_child(_panel_content)

func _build_bottom_navigation() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 16.0
	panel.offset_top = -88.0
	panel.offset_right = -16.0
	panel.offset_bottom = -14.0
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#292c27"), 0.96, 12))
	add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	_add_nav_button(row, "SETTLEMENT", "village")
	_add_nav_button(row, "PEOPLE", "people")
	_add_nav_button(row, "KNOWLEDGE", "knowledge")
	_add_nav_button(row, "CHRONICLE", "chronicle")
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	_add_button(row, "SAVE", _on_save, false)
	_add_button(row, "LOAD", _on_load, false)

func _build_status_toast() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	panel.offset_left = 16.0
	panel.offset_top = -132.0
	panel.offset_right = 420.0
	panel.offset_bottom = -96.0
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#292c27"), 0.90, 8))
	add_child(panel)
	_status_label = Label.new()
	_status_label.text = "A new settlement takes root."
	_status_label.add_theme_color_override("font_color", Color("#f0dfbd"))
	_status_label.add_theme_font_size_override("font_size", 12)
	panel.add_child(_status_label)

func _add_nav_button(parent: Control, caption: String, view_id: String) -> void:
	_add_button(parent, caption, _on_change_view.bind(view_id), view_id == _active_view)

func _add_button(parent: Control, caption: String, callback: Callable, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = caption
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size.y = 30.0
	button.add_theme_font_size_override("font_size", 11)
	var normal := _panel_style(Color("#8b744e") if primary else Color("#41443a"), 1.0, 7)
	var hover := _panel_style(Color("#a58a5a") if primary else Color("#565a49"), 1.0, 7)
	var pressed := _panel_style(Color("#6d5a3f") if primary else Color("#34382f"), 1.0, 7)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color("#f6ebd5"))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _panel_style(color: Color, alpha: float, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, alpha)
	style.border_color = Color("#796b50")
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 9.0
	style.content_margin_bottom = 9.0
	return style

func _refresh() -> void:
	if _simulation == null:
		return
	_refresh_hud()
	_world.set_simulation_minute(_simulation.clock.current_minute)
	var built_facilities: Array[String] = []
	for facility: Dictionary in _simulation.facilities.get_entries(_simulation.knowledge, _simulation.resources):
		if bool(facility.built):
			built_facilities.append(str(facility.id))
	_world.set_built_facilities(built_facilities)
	_world.set_selected_entity(_selected_type, _selected_id)
	_refresh_side_panel()

func _refresh_hud() -> void:
	for resource_id: String in RESOURCE_ORDER:
		var amount_label: Label = _resource_labels[resource_id]
		amount_label.text = str(_simulation.resources.get_amount(resource_id))
	var time_label: Label = get_node("TimeLabel") if has_node("TimeLabel") else null
	if time_label == null:
		time_label = find_child("TimeLabel", true, false) as Label
	if time_label != null:
		time_label.text = _simulation.clock.format_time()

func _refresh_side_panel() -> void:
	for child: Node in _panel_content.get_children():
		_panel_content.remove_child(child)
		child.queue_free()
	match _active_view:
		"village":
			_refresh_village_panel()
		"people":
			_refresh_people_panel()
		"knowledge":
			_refresh_knowledge_panel()
		"chronicle":
			_refresh_chronicle_panel()

func _refresh_village_panel() -> void:
	if _selected_type == "npc":
		var npc: Dictionary = _simulation.population.get_npc(_selected_id)
		_panel_title.text = str(npc.get("name", "Villager")).to_upper()
		_panel_body.text = "%s  ·  Age %d" % [str(npc.get("role", "Resident")), int(npc.get("age", 0))]
		_add_button(_panel_content, "TALK", func() -> void: _on_change_view("people"), true)
	else:
		_panel_title.text = "FARMSTEAD"
		_panel_body.text = "The heart of the settlement. Fields, stores and a place for the first ideas to take root."
		var entries: Array[Dictionary] = _simulation.facilities.get_entries(_simulation.knowledge, _simulation.resources)
		for entry: Dictionary in entries:
			var row := HBoxContainer.new()
			_panel_content.add_child(row)
			var details := VBoxContainer.new()
			details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(details)
			var name_label := Label.new()
			name_label.text = str(entry.name)
			name_label.add_theme_color_override("font_color", Color("#f0dfbd"))
			details.add_child(name_label)
			var state := Label.new()
			state.text = "ESTABLISHED" if bool(entry.built) else _facility_reason(entry)
			state.add_theme_color_override("font_color", Color("#b9aa8c"))
			state.add_theme_font_size_override("font_size", 10)
			details.add_child(state)
			if not bool(entry.built):
				var build := _add_button(row, "BUILD", _on_build.bind(str(entry.id)), bool(entry.can_build))
				build.disabled = not bool(entry.can_build)
		var progress: Dictionary = _campaign_progress.get_progress(_simulation)
		var objective_label := Label.new()
		objective_label.text = "FIRST SPARK  ·  %d / %d" % [int(progress.completed), int(progress.total)]
		objective_label.add_theme_color_override("font_color", Color("#e0c68e"))
		_panel_content.add_child(objective_label)
		for objective: Dictionary in progress.objectives:
			var item := Label.new()
			item.text = ("✓  " if bool(objective.complete) else "○  ") + str(objective.title)
			item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			item.add_theme_font_size_override("font_size", 11)
			item.add_theme_color_override("font_color", Color("#c9bea7"))
			_panel_content.add_child(item)

func _refresh_people_panel() -> void:
	_panel_title.text = "THE PEOPLE"
	_panel_body.text = _simulation.population.get_overview_text()
	for npc_id: String in _simulation.population.get_npc_ids():
		var npc: Dictionary = _simulation.population.get_npc(npc_id)
		var button := _add_button(_panel_content, "%s  ·  %s" % [str(npc.name), str(npc.role)], _on_select_npc.bind(npc_id), npc_id == _selected_npc_id)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_dialogue_input = LineEdit.new()
	_dialogue_input.placeholder_text = "Speak with the selected villager…"
	_panel_content.add_child(_dialogue_input)
	_add_button(_panel_content, "SEND", _on_send_dialogue, true)
	_dialogue_output = Label.new()
	_dialogue_output.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_output.text = "Select a villager to begin a conversation."
	_dialogue_output.add_theme_color_override("font_color", Color("#e0c68e"))
	_panel_content.add_child(_dialogue_output)

func _refresh_knowledge_panel() -> void:
	_panel_title.text = "KNOWLEDGE"
	_panel_body.text = "Ideas spread through observation, practice and shared work."
	for entry: Dictionary in _simulation.knowledge.get_knowledge_entries(_simulation.population, _simulation.resources):
		var row := HBoxContainer.new()
		_panel_content.add_child(row)
		var label := Label.new()
		label.text = str(entry.name)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(label)
		if bool(entry.known):
			var known := Label.new()
			known.text = "KNOWN"
			known.add_theme_color_override("font_color", Color("#c3bd8b"))
			row.add_child(known)
		else:
			var study := _add_button(row, "STUDY", _on_study.bind(str(entry.id)), bool(entry.can_study))
			study.disabled = not bool(entry.can_study)
			study.tooltip_text = _knowledge_reason(entry)
	var divider := HSeparator.new()
	_panel_content.add_child(divider)
	for entry: Dictionary in _simulation.knowledge.get_invention_entries(_simulation.population, _simulation.resources, _simulation.facilities):
		var row := HBoxContainer.new()
		_panel_content.add_child(row)
		var label := Label.new()
		label.text = str(entry.name)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(label)
		var invention_id: String = str(entry.id)
		if bool(entry.can_prototype):
			_add_button(row, "PROTOTYPE", _on_prototype.bind(invention_id), true)
		elif bool(entry.can_test):
			_add_button(row, "TEST", _on_test.bind(invention_id), true)
		elif bool(entry.can_commission):
			_add_button(row, "READY", _on_commission.bind(invention_id), true)
		elif bool(entry.can_produce):
			_add_button(row, "MAKE", _on_produce.bind(invention_id), true)

func _refresh_chronicle_panel() -> void:
	_panel_title.text = "CHRONICLE"
	_panel_body.text = "The choices made here will shape the settlement's history."
	for event: Dictionary in _simulation.timeline.get_pending_events():
		var event_panel := PanelContainer.new()
		event_panel.add_theme_stylebox_override("panel", _panel_style(Color("#424338"), 1.0, 8))
		_panel_content.add_child(event_panel)
		var stack := VBoxContainer.new()
		event_panel.add_child(stack)
		var title := Label.new()
		title.text = str(event.title)
		title.add_theme_color_override("font_color", Color("#f0dfbd"))
		title.add_theme_font_size_override("font_size", 14)
		stack.add_child(title)
		var description := Label.new()
		description.text = str(event.description)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stack.add_child(description)
		for choice: Dictionary in event.choices:
			var choice_button := _add_button(stack, str(choice.label), _on_timeline_choice.bind(str(event.id), str(choice.id)), false)
			choice_button.tooltip_text = str(choice.description)
	for entry: Dictionary in _simulation.timeline.get_timeline_entries():
		_panel_content.add_child(_make_small_label("%s  ·  %s" % [str(entry.title), str(entry.status).to_upper()]))

func _make_small_label(value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color("#c9bea7"))
	return label

func _facility_reason(entry: Dictionary) -> String:
	var reasons: Array[String] = []
	for item: String in entry.missing_knowledge:
		reasons.append("Requires " + item.replace("_", " "))
	for item: String in entry.missing_resources:
		reasons.append("Needs " + item)
	return " · ".join(reasons) if not reasons.is_empty() else "Ready to build"

func _knowledge_reason(entry: Dictionary) -> String:
	var reasons: Array[String] = []
	for item: String in entry.missing_knowledge:
		reasons.append("Requires " + item.replace("_", " "))
	for item: String in entry.missing_resources:
		reasons.append("Needs " + item)
	if not str(entry.missing_skills).is_empty():
		reasons.append(str(entry.missing_skills))
	return " · ".join(reasons)

func _clear_selection() -> void:
	_selected_type = "building"
	_selected_id = "farmstead"
	_refresh()

func _on_world_entity_selected(entity_type: String, entity_id: String) -> void:
	_selected_type = entity_type
	_selected_id = entity_id
	if entity_type == "npc":
		_selected_npc_id = entity_id
	_refresh()

func _on_change_view(view_id: String) -> void:
	_active_view = view_id
	_refresh_side_panel()

func _on_select_npc(npc_id: String) -> void:
	_selected_npc_id = npc_id
	_selected_type = "npc"
	_selected_id = npc_id
	_world.set_selected_entity("npc", npc_id)
	_refresh_side_panel()
	if _dialogue_output != null:
		_dialogue_output.text = "%s is here." % str(_simulation.population.get_npc(npc_id).get("name", npc_id))

func _on_send_dialogue() -> void:
	if _selected_npc_id.is_empty() or _dialogue_input == null:
		return
	var result: Dictionary = _simulation.request_npc_dialogue(_selected_npc_id, _dialogue_input.text)
	if not result.ok:
		_dialogue_output.text = str(result.error)
		return
	_dialogue_output.text = str(result.proposal.dialogue_text)
	_dialogue_input.clear()

func _on_advance(minutes: int) -> void:
	var result: Dictionary = _simulation.advance_time(minutes)
	_set_status("Time moves forward." if result.ok else str(result.error))
	_refresh()

func _on_save() -> void:
	var snapshot: Dictionary = {
		"campaign_id": "first-spark-local",
		"simulation_minute": _simulation.clock.current_minute,
		"state": _simulation.create_save_state()
	}
	var result: Dictionary = SaveManager.new().save_snapshot("user://saves/first_spark.json", snapshot)
	_set_status("Settlement saved." if result.ok else str(result.error))

func _on_load() -> void:
	var loaded: Dictionary = SaveManager.new().load_snapshot("user://saves/first_spark.json")
	if not loaded.ok:
		_set_status(str(loaded.error))
		return
	if str(loaded.data.get("campaign_id", "")) != "first-spark-local":
		_set_status("Save belongs to another campaign.")
		return
	var restored: SettlementSimulation = SettlementSimulation.new()
	var result: Dictionary = restored.restore_save_state(int(loaded.data.simulation_minute), loaded.data.state)
	if not result.ok:
		_set_status(str(result.error))
		return
	_simulation = restored
	_set_status("Recovered the previous verified save." if bool(loaded.get("recovered_from_backup", false)) else "Settlement loaded.")
	_refresh()

func _on_study(knowledge_id: String) -> void:
	var result: Dictionary = _simulation.knowledge.study_knowledge(knowledge_id, _simulation.population, _simulation.resources)
	_set_status("Knowledge discovered." if result.ok else str(result.error))
	_refresh()

func _on_build(facility_id: String) -> void:
	var result: Dictionary = _simulation.build_facility(facility_id)
	_set_status("New building raised." if result.ok else str(result.error))
	_refresh()

func _on_prototype(invention_id: String) -> void:
	var result: Dictionary = _simulation.knowledge.attempt_prototype(invention_id, _simulation.population, _simulation.resources)
	_set_status("Prototype assembled." if result.ok else str(result.error))
	_refresh()

func _on_test(invention_id: String) -> void:
	var result: Dictionary = _simulation.knowledge.test_prototype(invention_id, _simulation.population)
	_set_status("Prototype validated." if result.ok and result.validated else str(result.get("reason", result.get("error", "Test incomplete."))))
	_refresh()

func _on_commission(invention_id: String) -> void:
	var result: Dictionary = _simulation.knowledge.commission_production(invention_id)
	_set_status("Production commissioned." if result.ok else str(result.error))
	_refresh()

func _on_produce(invention_id: String) -> void:
	var result: Dictionary = _simulation.produce_invention(invention_id)
	_set_status("Production completed." if result.ok else str(result.error))
	_refresh()

func _on_timeline_choice(event_id: String, choice_id: String) -> void:
	var result: Dictionary = _simulation.resolve_historical_choice(event_id, choice_id)
	_set_status("The village remembers this choice." if result.ok else str(result.error))
	_refresh()

func _set_status(message: String) -> void:
	_status_label.text = message
