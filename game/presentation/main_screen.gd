extends Control
## Responsive first-slice dashboard. Presentation only; domain state remains outside the scene.

const SimulationClock = preload("res://game/domain/simulation/simulation_clock.gd")
const ContentCatalog = preload("res://game/infrastructure/content/content_catalog.gd")

var _clock: SimulationClock


func _ready() -> void:
	_clock = SimulationClock.new(8 * 60)
	_build_screen()


func _build_screen() -> void:
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)

	var page: VBoxContainer = VBoxContainer.new()
	page.add_theme_constant_override("separation", 16)
	margin.add_child(page)

	var title: Label = Label.new()
	title.text = "THE FIRST SPARK"
	title.add_theme_font_size_override("font_size", 30)
	page.add_child(title)

	var subtitle: Label = Label.new()
	subtitle.text = "A settlement at the edge of a different future"
	subtitle.add_theme_font_size_override("font_size", 15)
	page.add_child(subtitle)

	page.add_child(HSeparator.new())

	var time_label: Label = Label.new()
	time_label.text = "SIMULATION  ·  " + _clock.format_time()
	time_label.add_theme_font_size_override("font_size", 20)
	page.add_child(time_label)

	var resource_heading: Label = Label.new()
	resource_heading.text = "SETTLEMENT RESOURCES"
	resource_heading.add_theme_font_size_override("font_size", 16)
	page.add_child(resource_heading)

	var resource_result: Dictionary = ContentCatalog.load_collection("res://content/resources.json", "resources")
	var resource_flow: HFlowContainer = HFlowContainer.new()
	resource_flow.add_theme_constant_override("h_separation", 10)
	resource_flow.add_theme_constant_override("v_separation", 10)
	page.add_child(resource_flow)
	if resource_result["ok"]:
		for resource: Dictionary in resource_result["items"]:
			resource_flow.add_child(_make_stat_card(str(resource["name"]), str(resource["starting_amount"]) + " " + str(resource["unit"])))
	else:
		resource_flow.add_child(_make_stat_card("Content error", str(resource_result["error"])))

	var people_heading: Label = Label.new()
	people_heading.text = "PEOPLE TO KNOW"
	people_heading.add_theme_font_size_override("font_size", 16)
	page.add_child(people_heading)

	var npc_result: Dictionary = ContentCatalog.load_collection("res://content/npcs.json", "npcs")
	var npc_flow: HFlowContainer = HFlowContainer.new()
	npc_flow.add_theme_constant_override("h_separation", 10)
	npc_flow.add_theme_constant_override("v_separation", 10)
	page.add_child(npc_flow)
	if npc_result["ok"]:
		for npc: Dictionary in npc_result["items"]:
			npc_flow.add_child(_make_stat_card(str(npc["name"]), str(npc["role"])))
	else:
		npc_flow.add_child(_make_stat_card("Content error", str(npc_result["error"])))

	var note: Label = Label.new()
	note.text = "Foundation build 0.2.0  ·  Simulation is deterministic; this screen is a presentation shell."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_spacer(false)
	page.add_child(note)


func _make_stat_card(heading: String, value: String) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(175, 78)
	var stack: VBoxContainer = VBoxContainer.new()
	stack.add_theme_constant_override("separation", 5)
	panel.add_child(stack)
	var heading_label: Label = Label.new()
	heading_label.text = heading
	heading_label.add_theme_font_size_override("font_size", 14)
	stack.add_child(heading_label)
	var value_label: Label = Label.new()
	value_label.text = value
	value_label.add_theme_font_size_override("font_size", 17)
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(value_label)
	return panel
