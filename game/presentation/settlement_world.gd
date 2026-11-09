class_name SettlementWorld
extends Node2D
## Lightweight hand-painted isometric settlement renderer.
## The world is presentation-only: all authoritative state remains in SettlementSimulation.

signal entity_selected(entity_type: String, entity_id: String)

const TILE_HALF_WIDTH: float = 48.0
const TILE_HALF_HEIGHT: float = 24.0
const INK: Color = Color("#342a25")
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

var _camera_offset: Vector2 = Vector2.ZERO
var _zoom: float = 1.0
var _dragging: bool = false
var _drag_moved: bool = false
var _last_mouse: Vector2 = Vector2.ZERO
var _elapsed: float = 0.0
var _simulation_minute: int = 480
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
	_draw_water()
	_draw_paths()
	_draw_farm_plots()
	_draw_trees()
	_draw_farmstead()
	_draw_props()
	_draw_npcs()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_terrain() -> void:
	for row: int in range(12):
		for column: int in range(15):
			var center := Vector2(
				float(column - row - 7) * TILE_HALF_WIDTH,
				float(column + row - 18) * TILE_HALF_HEIGHT
			)
			var variation: int = posmod(column * 7 + row * 11, GRASS.size())
			var points := _diamond(center, TILE_HALF_WIDTH, TILE_HALF_HEIGHT)
			draw_colored_polygon(points, GRASS[variation])
			draw_polyline(_closed(points), Color("#526b49"), 1.2, true)
			if posmod(column * 13 + row * 5, 9) == 0:
				draw_circle(center + Vector2(-9.0, -3.0), 1.8, Color("#9aaa70"))
				draw_circle(center + Vector2(13.0, 5.0), 1.2, Color("#a8ad78"))

func _draw_water() -> void:
	var river := PackedVector2Array([
		Vector2(350.0, -310.0), Vector2(300.0, -190.0),
		Vector2(335.0, -55.0), Vector2(285.0, 85.0),
		Vector2(340.0, 230.0), Vector2(305.0, 340.0)
	])
	draw_polyline(river, Color("#425b50"), 43.0, true)
	draw_polyline(river, Color("#789e9b"), 35.0, true)
	draw_polyline(river, Color("#a8c1ad"), 2.0, true)
	for index: int in range(5):
		var point := Vector2(315.0 + sin(_elapsed * 0.7 + float(index)) * 10.0, -190.0 + float(index) * 100.0)
		draw_line(point, point + Vector2(15.0, -3.0), Color("#d0d0a4"), 1.5)

func _draw_paths() -> void:
	var path := PackedVector2Array([
		Vector2(-365.0, 180.0), Vector2(-230.0, 110.0),
		Vector2(-95.0, 65.0), Vector2(40.0, 110.0),
		Vector2(180.0, 60.0), Vector2(290.0, -20.0)
	])
	draw_polyline(path, Color("#66513c"), 31.0, true)
	draw_polyline(path, Color("#b59a70"), 25.0, true)
	draw_polyline(path, Color("#d0b78d"), 1.5, true)
	var branch := PackedVector2Array([Vector2(-95.0, 65.0), Vector2(-75.0, -35.0), Vector2(-95.0, -135.0)])
	draw_polyline(branch, Color("#66513c"), 25.0, true)
	draw_polyline(branch, Color("#b59a70"), 19.0, true)

func _draw_farm_plots() -> void:
	for plot_index: int in range(3):
		var center := Vector2(-350.0 + float(plot_index) * 4.0, 250.0 + float(plot_index) * 20.0)
		var points := _diamond(center, 68.0, 27.0)
		draw_colored_polygon(points, Color("#755d42"))
		draw_polyline(_closed(points), Color("#4a3b2e"), 2.0, true)
		for row: int in range(3):
			for plant: int in range(6):
				var x: float = center.x - 40.0 + float(plant) * 16.0
				var y: float = center.y - 10.0 + float(row) * 9.0
				var growth: float = 5.0 + 2.0 * sin(_elapsed * 1.8 + float(plant + row))
				draw_line(Vector2(x, y), Vector2(x - 2.0, y - growth), Color("#405a38"), 2.0)
				draw_circle(Vector2(x - 3.0, y - growth), 2.4, Color("#a5a85e"))

func _draw_trees() -> void:
	var positions: Array[Vector2] = [
		Vector2(-420.0, -120.0), Vector2(-355.0, -205.0),
		Vector2(-300.0, -260.0), Vector2(5.0, -300.0),
		Vector2(125.0, -260.0), Vector2(230.0, -215.0),
		Vector2(430.0, -130.0), Vector2(420.0, 170.0),
		Vector2(210.0, 260.0), Vector2(-460.0, 270.0)
	]
	for index: int in range(positions.size()):
		_draw_tree(positions[index], 0.82 + float(posmod(index * 7, 5)) * 0.09, index)

func _draw_tree(position: Vector2, scale: float, seed: int) -> void:
	var sway: float = sin(_elapsed * 1.1 + float(seed)) * 2.0
	draw_ellipse(position + Vector2(0.0, 7.0), Vector2(21.0, 10.0) * scale, Color("#536447"))
	draw_rect(Rect2(position + Vector2(-5.0, -43.0) * scale, Vector2(10.0, 48.0) * scale), Color("#72513b"))
	draw_line(position + Vector2(0.0, -38.0) * scale, position + Vector2(0.0, -5.0) * scale, Color("#a17b54"), 2.0)
	var crown := position + Vector2(sway, -60.0 * scale)
	draw_circle(crown, 29.0 * scale, Color("#3e5c3f"))
	draw_circle(crown + Vector2(-15.0, -9.0) * scale, 20.0 * scale, Color("#59784a"))
	draw_circle(crown + Vector2(13.0, -14.0) * scale, 19.0 * scale, Color("#718a51"))
	draw_arc(crown + Vector2(-2.0, -2.0), 27.0 * scale, 3.4, 5.3, 16, Color("#a0a76a"), 1.4)

func _draw_farmstead() -> void:
	var center := Vector2(-82.0, -62.0)
	draw_ellipse(center + Vector2(0.0, 45.0), Vector2(92.0, 31.0), Color("#4f6043"))
	var base := PackedVector2Array([
		center + Vector2(-62.0, -35.0), center + Vector2(0.0, -67.0),
		center + Vector2(65.0, -34.0), center + Vector2(65.0, 35.0),
		center + Vector2(0.0, 67.0), center + Vector2(-62.0, 35.0)
	])
	draw_colored_polygon(base, Color("#c5a77d"))
	draw_polyline(_closed(base), INK, 3.0, true)
	var front := PackedVector2Array([
		center + Vector2(-62.0, -35.0), center + Vector2(0.0, -4.0),
		center + Vector2(0.0, 67.0), center + Vector2(-62.0, 35.0)
	])
	draw_colored_polygon(front, Color("#a9845f"))
	draw_polyline(_closed(front), INK, 2.0, true)
	var side := PackedVector2Array([
		center + Vector2(0.0, -4.0), center + Vector2(65.0, -34.0),
		center + Vector2(65.0, 35.0), center + Vector2(0.0, 67.0)
	])
	draw_colored_polygon(side, Color("#d2b58a"))
	draw_polyline(_closed(side), INK, 2.0, true)
	var roof_left := PackedVector2Array([
		center + Vector2(-76.0, -38.0), center + Vector2(-7.0, -105.0),
		center + Vector2(5.0, -98.0), center + Vector2(-62.0, -24.0)
	])
	var roof_right := PackedVector2Array([
		center + Vector2(-7.0, -105.0), center + Vector2(78.0, -43.0),
		center + Vector2(68.0, -29.0), center + Vector2(5.0, -98.0)
	])
	draw_colored_polygon(roof_left, Color("#68463a"))
	draw_colored_polygon(roof_right, Color("#8c5943"))
	draw_polyline(_closed(roof_left), INK, 3.0, true)
	draw_polyline(_closed(roof_right), INK, 3.0, true)
	draw_line(center + Vector2(-49.0, -45.0), center + Vector2(-2.0, -91.0), Color("#b47b56"), 2.0)
	draw_line(center + Vector2(10.0, -91.0), center + Vector2(62.0, -47.0), Color("#bd8056"), 2.0)
	draw_rect(Rect2(center + Vector2(-16.0, 20.0), Vector2(26.0, 47.0)), Color("#563d31"))
	draw_rect(Rect2(center + Vector2(-52.0, -8.0), Vector2(19.0, 18.0)), Color("#5e7770"))
	draw_rect(Rect2(center + Vector2(25.0, -10.0), Vector2(20.0, 18.0)), Color("#5e7770"))
	draw_line(center + Vector2(-52.0, 0.0), center + Vector2(-33.0, 0.0), Color("#e2c99c"), 2.0)
	draw_line(center + Vector2(-42.0, -8.0), center + Vector2(-42.0, 10.0), Color("#e2c99c"), 2.0)
	if _selected_type == "building" and _selected_id == "farmstead":
		var highlight := PackedVector2Array([
			center + Vector2(-87.0, -40.0), center + Vector2(-5.0, -121.0),
			center + Vector2(89.0, -44.0), center + Vector2(77.0, 43.0),
			center + Vector2(-3.0, 82.0), center + Vector2(-80.0, 43.0)
		])
		draw_polyline(_closed(highlight), Color("#f2d58a"), 3.0, true)

func _draw_props() -> void:
	# Wood stack and a small handcart make the farmstead feel occupied.
	draw_rect(Rect2(Vector2(-210.0, 5.0), Vector2(38.0, 13.0)), Color("#78533b"))
	draw_rect(Rect2(Vector2(-205.0, -5.0), Vector2(34.0, 12.0)), Color("#a77a4e"))
	draw_circle(Vector2(-190.0, 22.0), 7.0, INK)
	draw_circle(Vector2(-190.0, 22.0), 3.5, Color("#b7a17c"))
	draw_line(Vector2(-190.0, 22.0), Vector2(-160.0, 5.0), INK, 3.0)
	draw_ellipse(Vector2(15.0, 170.0), Vector2(33.0, 15.0), Color("#5b6b46"))
	draw_colored_polygon(_diamond(Vector2(15.0, 155.0), 23.0, 13.0), Color("#b49a6c"))

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
				_dragging = true
				_drag_moved = false
				_last_mouse = mouse_event.position
			else:
				if _dragging and not _drag_moved:
					_select_at(mouse_event.position)
				_dragging = false
				return
		elif mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at(mouse_event.position, 1.12)
		elif mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at(mouse_event.position, 1.0 / 1.12)
	elif event is InputEventMouseMotion and _dragging:
		var motion := event as InputEventMouseMotion
		if motion.position.distance_to(_last_mouse) > 4.0:
			_drag_moved = true
		_camera_offset += motion.position - _last_mouse
		_last_mouse = motion.position
		queue_redraw()
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
