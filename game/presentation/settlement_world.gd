class_name SettlementWorld
extends Node2D
## Lightweight hand-painted isometric settlement renderer.
## The world is presentation-only: all authoritative state remains in SettlementSimulation.

signal entity_selected(entity_type: String, entity_id: String)

const TILE_HALF_WIDTH: float = 48.0
const TILE_HALF_HEIGHT: float = 24.0
const INK: Color = Color("#342a25")
const TILE_SCALE: float = 0.375
const TILE_SIZE: Vector2 = Vector2(96.0, 132.0)
const TEX_GRASS: Texture2D = preload("res://assets/kenney/sketch-town/grass_center_S.png")
const TEX_PATH: Texture2D = preload("res://assets/kenney/sketch-town/grass_path_S.png")
const TEX_RIVER: Texture2D = preload("res://assets/kenney/sketch-town/grass_river_S.png")
const TEX_TREE: Texture2D = preload("res://assets/kenney/sketch-town/tree_single_S.png")
const TEX_TREE_CLUSTER: Texture2D = preload("res://assets/kenney/sketch-town/tree_multiple_S.png")
const TEX_BUILDING: Texture2D = preload("res://assets/kenney/sketch-town/building_doorWindowsBeige_S.png")
const TEX_ROOF: Texture2D = preload("res://assets/kenney/sketch-town/roof_gableBeige_S.png")
const TEX_BRIDGE: Texture2D = preload("res://assets/kenney/sketch-town/bridge_S.png")
const TEX_CROPS: Texture2D = preload("res://assets/kenney/sketch-town/furrow_cropWheat_S.png")
const TEX_WELL: Texture2D = preload("res://assets/kenney/sketch-town/well_S.png")
const TEX_PINE: Texture2D = preload("res://assets/kenney/sketch-town/tree_pineLarge_S.png")
const TEX_FENCE: Texture2D = preload("res://assets/kenney/sketch-town/fence_wood_S.png")
const GRASS: Array[Color] = [
	Color("#71885a"), Color("#788e5e"), Color("#6d8355"),
	Color("#819363"), Color("#74895a")
]
const NPC_COLORS: Dictionary = {
	"mara": Color("#9c6570"),
	"edric": Color("#647e8c"),
	"elin": Color("#d2a45f"),
	"tomas": Color("#8b7664"),
	"aldwin": Color("#8a8060")
}
const NPC_POSITIONS: Dictionary = {
	"mara": Vector2(-220.0, 45.0),
	"edric": Vector2(105.0, 68.0),
	"elin": Vector2(-145.0, 145.0),
	"tomas": Vector2(175.0, -70.0),
	"aldwin": Vector2(45.0, -145.0)
}
const FACILITY_POSITIONS: Dictionary = {
	"workshop": Vector2(145.0, -150.0),
	"forge": Vector2(225.0, 145.0),
	"watermill": Vector2(365.0, -45.0)
}

var _camera_offset: Vector2 = Vector2.ZERO
var _zoom: float = 1.0
var _dragging: bool = false
var _drag_moved: bool = false
var _pending_click: bool = false
var _pending_click_position: Vector2 = Vector2.ZERO
var _last_mouse: Vector2 = Vector2.ZERO
var _elapsed: float = 0.0
var _simulation_minute: int = 480
var _built_facilities: Array[String] = ["farmstead"]
var _selected_type: String = "building"
var _selected_id: String = "farmstead"

func _ready() -> void:
	_center_camera()
	set_process(true)
	set_process_input(true)

func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()

func set_simulation_minute(value: int) -> void:
	_simulation_minute = maxi(0, value)

func set_built_facilities(value: Array[String]) -> void:
	_built_facilities = value.duplicate()
	queue_redraw()

func set_selected_entity(entity_type: String, entity_id: String) -> void:
	_selected_type = entity_type
	_selected_id = entity_id
	queue_redraw()

func _center_camera() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	_camera_offset = viewport_size * 0.5

func _draw() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("#a9b49a"))
	draw_set_transform(_camera_offset, 0.0, Vector2(_zoom, _zoom))
	_draw_terrain()
	_draw_trees()
	_draw_farmstead()
	_draw_facilities()
	_draw_props()
	_draw_npcs()
	_draw_daylight()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_terrain() -> void:
	# Isometric cubes are drawn back-to-front by diagonal depth so their side faces
	# overlap consistently instead of producing a flat, checkerboard map.
	for depth: int in range(26):
		for row: int in range(12):
			var column: int = depth - row
			if column < 0 or column >= 15:
				continue
			var center := Vector2(
				float(column - row - 7) * TILE_HALF_WIDTH,
				float(column + row - 18) * TILE_HALF_HEIGHT
			)
			var texture: Texture2D = TEX_GRASS
			if row == 6 and column >= 1 and column <= 13:
				texture = TEX_PATH
			elif row == 5 and column >= 2 and column <= 5:
				texture = TEX_PATH
			elif row == 3 and column >= 9 and column <= 14:
				texture = TEX_RIVER
			elif row == 4 and column >= 11 and column <= 14:
				texture = TEX_RIVER
			elif row == 8 and column >= 2 and column <= 4:
				texture = TEX_CROPS
			elif row == 9 and column >= 2 and column <= 4:
				texture = TEX_CROPS
			draw_texture_rect(texture, Rect2(center - TILE_SIZE * 0.5, TILE_SIZE), false)

func _draw_water() -> void:
	# Water is authored directly into the ground tiles; this function remains
	# intentionally empty so the renderer does not add a mismatched vector river.

func _draw_paths() -> void:
	# Paths are authored into the ground tile selection in _draw_terrain().

func _draw_farm_plots() -> void:
	# Crop furrows are part of the terrain tile pass.

func _draw_trees() -> void:
	var positions: Array[Vector2] = [
		Vector2(-420.0, -120.0), Vector2(-355.0, -205.0),
		Vector2(-300.0, -260.0), Vector2(5.0, -300.0),
		Vector2(125.0, -260.0), Vector2(230.0, -215.0),
		Vector2(430.0, -130.0), Vector2(420.0, 170.0),
		Vector2(210.0, 260.0), Vector2(-460.0, 270.0)
	]
	for index: int in range(positions.size()):
		var texture: Texture2D = TEX_TREE_CLUSTER if posmod(index, 3) == 0 else TEX_TREE
		if posmod(index, 5) == 0:
			texture = TEX_PINE
		_draw_ground_sprite(texture, positions[index], TILE_SCALE, Color.WHITE)

func _draw_tree(position: Vector2, scale: float, seed: int) -> void:
	var texture: Texture2D = TEX_TREE_CLUSTER if seed % 2 == 0 else TEX_TREE
	_draw_ground_sprite(texture, position, scale * TILE_SCALE, Color.WHITE)

func _draw_farmstead() -> void:
	var center := Vector2(-82.0, -62.0)
	_draw_building_sprite(center, Color.WHITE)
	if _selected_type == "building" and _selected_id == "farmstead":
		draw_polyline(_closed(_diamond(center + Vector2(0.0, 12.0), 68.0, 36.0)), Color("#f2d58a"), 3.0, true)

func _draw_facilities() -> void:
	var tints: Dictionary = {
		"workshop": Color("#e4d5bb"),
		"forge": Color("#c9b8a8"),
		"watermill": Color("#d4e1d5")
	}
	for facility_id: String in FACILITY_POSITIONS:
		if not _built_facilities.has(facility_id):
			continue
		var center: Vector2 = FACILITY_POSITIONS[facility_id]
		_draw_building_sprite(center, tints[facility_id])
		if facility_id == "forge":
			var smoke := center + Vector2(24.0, -83.0 - fposmod(_elapsed * 8.0, 13.0))
			draw_circle(smoke, 5.0, Color(0.68, 0.66, 0.59, 0.32))
			draw_circle(smoke + Vector2(6.0, -7.0), 4.0, Color(0.68, 0.66, 0.59, 0.22))
		if _selected_type == "building" and _selected_id == facility_id:
			draw_polyline(_closed(_diamond(center + Vector2(0.0, 12.0), 68.0, 36.0)), Color("#f2d58a"), 3.0, true)

func _draw_building_sprite(center: Vector2, tint: Color) -> void:
	# The building and roof use the same authored tile footprint. A slight
	# vertical roof lift keeps the gable clear of the window/door facade.
	_draw_iso_sprite(TEX_BUILDING, center, TILE_SCALE, tint)
	_draw_iso_sprite(TEX_ROOF, center + Vector2(0.0, -27.0), TILE_SCALE, Color.WHITE)

func _draw_iso_sprite(texture: Texture2D, center: Vector2, scale_factor: float, tint: Color) -> void:
	var size: Vector2 = Vector2(texture.get_size()) * scale_factor
	draw_texture_rect(texture, Rect2(center - size * 0.5, size), false, tint)

func _draw_ground_sprite(texture: Texture2D, ground_position: Vector2, scale_factor: float, tint: Color) -> void:
	var size: Vector2 = Vector2(texture.get_size()) * scale_factor
	var ground_anchor: float = size.y * 0.91
	draw_texture_rect(texture, Rect2(
		ground_position - Vector2(size.x * 0.5, ground_anchor),
		size
	), false, tint)

func _draw_daylight() -> void:
	var hour: float = float(posmod(_simulation_minute, 1440)) / 60.0
	var darkness: float = 0.0
	if hour < 6.0 or hour >= 20.0:
		darkness = 0.27
	elif hour < 8.0:
		darkness = lerpf(0.27, 0.0, (hour - 6.0) / 2.0)
	elif hour >= 18.0:
		darkness = lerpf(0.0, 0.27, (hour - 18.0) / 2.0)
	if darkness > 0.0:
		draw_rect(Rect2(Vector2(-900.0, -600.0), Vector2(1800.0, 1200.0)), Color(0.10, 0.13, 0.22, darkness))

func _draw_props() -> void:
	_draw_ground_sprite(TEX_WELL, Vector2(15.0, 170.0), TILE_SCALE, Color.WHITE)
	_draw_iso_sprite(TEX_BRIDGE, Vector2(315.0, -45.0), TILE_SCALE, Color.WHITE)
	_draw_ground_sprite(TEX_FENCE, Vector2(-330.0, 230.0), TILE_SCALE * 0.78, Color.WHITE)
	_draw_ground_sprite(TEX_FENCE, Vector2(-270.0, 260.0), TILE_SCALE * 0.78, Color.WHITE)

func _draw_npcs() -> void:
	var ids: Array[String] = ["mara", "edric", "elin", "tomas", "aldwin"]
	for index: int in range(ids.size()):
		var npc_id: String = ids[index]
		var position: Vector2 = _npc_world_position(npc_id, index)
		_draw_npc(npc_id, position, index)

func _npc_world_position(npc_id: String, index: int) -> Vector2:
	var base: Vector2 = NPC_POSITIONS[npc_id]
	var phase: float = _elapsed * (0.55 + float(index) * 0.08) + float(index) * 2.1
	var activity_offset := Vector2(sin(phase) * 17.0, cos(phase * 0.7) * 5.0)
	return base + activity_offset

func _draw_npc(npc_id: String, position: Vector2, index: int) -> void:
	var bob: float = absf(sin(_elapsed * 3.2 + float(index))) * 2.0
	var body_color: Color = NPC_COLORS[npc_id]
	draw_ellipse(position + Vector2(0.0, 5.0), Vector2(13.0, 6.0), Color("#4b5940"))
	draw_line(position + Vector2(0.0, -1.0), position + Vector2(0.0, 16.0), INK, 8.0)
	draw_line(position + Vector2(0.0, bob), position + Vector2(0.0, 15.0 + bob), body_color, 6.0)
	draw_line(position + Vector2(-1.0, 5.0), position + Vector2(-9.0, 12.0 + sin(_elapsed * 4.0 + float(index)) * 2.0), INK, 3.0)
	draw_line(position + Vector2(1.0, 5.0), position + Vector2(9.0, 12.0 - sin(_elapsed * 4.0 + float(index)) * 2.0), body_color.lightened(0.12), 3.0)
	draw_circle(position + Vector2(0.0, -9.0 - bob), 6.5, Color("#d9b58e"))
	draw_arc(position + Vector2(0.0, -9.0 - bob), 6.5, PI, TAU, 12, INK, 1.4)
	draw_line(position + Vector2(-5.0, -13.0 - bob), position + Vector2(4.0, -15.0 - bob), Color("#594438"), 3.0)
	if _selected_type == "npc" and _selected_id == npc_id:
		draw_arc(position + Vector2(0.0, 2.0), 17.0, 0.0, TAU, 24, Color("#f4d88b"), 2.5)
		draw_circle(position + Vector2(0.0, -29.0), 2.5, Color("#f4d88b"))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_event.pressed:
				var hovered: Control = get_viewport().gui_get_hovered_control()
				if hovered != null:
					return
				_dragging = true
				_drag_moved = false
				_pending_click = false
				_last_mouse = mouse_event.position
			else:
				if _dragging and not _drag_moved:
					_pending_click = true
					_pending_click_position = mouse_event.position
				_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		var motion := event as InputEventMouseMotion
		if motion.position.distance_to(_last_mouse) > 4.0:
			_drag_moved = true
		_camera_offset += motion.position - _last_mouse
		_last_mouse = motion.position
		queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed and _pending_click:
			_select_at(_pending_click_position)
			_pending_click = false
		elif mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at(mouse_event.position, 1.12)
		elif mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at(mouse_event.position, 1.0 / 1.12)
	elif event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		var direction := Vector2.ZERO
		match key_event.keycode:
			KEY_A, KEY_LEFT: direction.x += 32.0
			KEY_D, KEY_RIGHT: direction.x -= 32.0
			KEY_W, KEY_UP: direction.y += 32.0
			KEY_S, KEY_DOWN: direction.y -= 32.0
			KEY_PLUS, KEY_EQUAL, KEY_KP_ADD: _zoom_at(get_viewport_rect().size * 0.5, 1.12)
			KEY_MINUS, KEY_KP_SUBTRACT: _zoom_at(get_viewport_rect().size * 0.5, 1.0 / 1.12)
		_camera_offset += direction
		queue_redraw()

func _zoom_at(screen_position: Vector2, factor: float) -> void:
	var world_position: Vector2 = (screen_position - _camera_offset) / _zoom
	_zoom = clampf(_zoom * factor, 0.62, 1.65)
	_camera_offset = screen_position - world_position * _zoom
	queue_redraw()


func _select_at(screen_position: Vector2) -> void:
	var world_position: Vector2 = (screen_position - _camera_offset) / _zoom
	var nearest_id: String = ""
	var nearest_distance: float = 28.0
	for npc_id: String in NPC_POSITIONS:
		var index: int = ["mara", "edric", "elin", "tomas", "aldwin"].find(npc_id)
		var distance: float = world_position.distance_to(_npc_world_position(npc_id, index))
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_id = npc_id
	if not nearest_id.is_empty():
		entity_selected.emit("npc", nearest_id)
		return
	if world_position.distance_to(Vector2(-82.0, -62.0)) < 105.0:
		entity_selected.emit("building", "farmstead")
		return
	for facility_id: String in FACILITY_POSITIONS:
		if _built_facilities.has(facility_id) and world_position.distance_to(FACILITY_POSITIONS[facility_id]) < 75.0:
			entity_selected.emit("building", facility_id)
			return

func _diamond(center: Vector2, half_width: float, half_height: float) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(0.0, -half_height),
		center + Vector2(half_width, 0.0),
		center + Vector2(0.0, half_height),
		center + Vector2(-half_width, 0.0)
	])

func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	if not points.is_empty():
		result.append(points[0])
	return result

func draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index: int in range(25):
		var angle: float = TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
