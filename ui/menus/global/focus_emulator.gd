class_name FocusEmulator
extends Node2D

export (Array, Resource) var focus_base_data

export (int) var player_index: int = - 1 setget _set_player_index
func _set_player_index(value: int) -> void :
	if value == player_index:
		return
	var control: = focused_control
	
	if control != null and player_index >= 0:
		_clear_focused_control()
		FocusEmulatorSignal.emit(control, "focus_exited", player_index)
	player_index = value
	
	_on_connected_players_updated(CoopService.connected_players)
	
	if control != null and player_index >= 0:
		_set_focused_control_with_style(control, false)
		FocusEmulatorSignal.emit(control, "focus_entered", player_index)

var focused_control: Control = null setget _set_focused_control
func _set_focused_control(control: Control) -> void :
	if control == null:
		var existing_focused_control = focused_control
		_clear_focused_control()
		if existing_focused_control != null:
			FocusEmulatorSignal.emit(existing_focused_control, "focus_exited", player_index)
	else:
		_set_focused_control_with_style(control, true)


var _device: int = - 1
var _focus_base_nodes: = []
var _focused_control_index: int = - 1
var _focused_control_connection
var _focused_parent: Control = null


func _ready() -> void :
	_on_connected_players_updated(CoopService.connected_players)
	var _e = CoopService.connect("connected_players_updated", self, "_on_connected_players_updated")

	for base in focus_base_data:
		var node = get_node(base.path)
		if node == null:
			printerr("Focus base not found: %s" % base.path)
			continue
		_focus_base_nodes.append(node)

	var _ee = get_viewport().connect("gui_focus_changed", self, "_on_focus_changed")


func _input(event: InputEvent) -> void :
	if _device < 0 or _focus_base_nodes.empty() or focused_control == null:
		return

	
	if (
		_is_coop_action(event, "ui_cancel")
		or _is_coop_action(event, "ui_pause")
		or _is_coop_action(event, "ltrigger")
		or _is_coop_action(event, "rtrigger")
		or BugReporter.visible
		or (event is InputEventKey and event.is_action("open_bug_report"))
	):
		return

	
	var focus_emulator_hidden: = true
	for focus_base_node in _focus_base_nodes:
		if focus_base_node.is_visible_in_tree():
			focus_emulator_hidden = false

	if focus_emulator_hidden:
		return

	
	
	
	if _handle_input(event) or ( not _is_coop_ui_action(event) and not CoopService.listening_for_inputs):
		get_tree().set_input_as_handled()
		return



func _draw() -> void :
	if focused_control == null:
		return

	
	var player_indices = focused_control.get_meta("focus_player_indices", [])
	if player_indices[0] != player_index:
		return

	var scroll_container = _find_parent_scroll_container(focused_control)
	
	if scroll_container != null and (scroll_container.scroll_horizontal != 0 or scroll_container.scroll_vertical != 0):
		var scroll_rect = scroll_container.get_global_rect()
		VisualServer.canvas_item_set_custom_rect(get_canvas_item(), true, scroll_rect)
		VisualServer.canvas_item_set_clip(get_canvas_item(), true)

	var focus_style_box = focused_control.get_stylebox("focus")
	
	for focus_order in range(player_indices.size() - 1, 0, - 1):
		var focus_player_index = player_indices[focus_order]
		var stylebox = StyleBoxFlat.new()
		stylebox.border_color = CoopService.get_player_color(focus_player_index);
		stylebox.draw_center = false
		stylebox.set_border_width_all(4 * focus_order)
		stylebox.set_expand_margin_all(4 * focus_order - 1)
		stylebox.set_corner_radius_all(focus_style_box.corner_radius_top_left * (1 + (focus_order - 1) * 0.2))
		draw_style_box(stylebox, focused_control.get_global_rect())


func _process(_delta: float) -> void :
	update()
	set_process(false)


func _handle_input(event: InputEvent) -> bool:
	var modal = get_viewport().get_modal_stack_top()
	if modal is PopupMenu:
		if _find_control_base_data(modal) != null:
			return _handle_popup_menu_input(event, modal)

	if not is_instance_valid(focused_control):
		
		var new = _focused_parent.get_child(_focused_control_index)
		_set_focused_control_with_style(new, false)

	if focused_control is HSlider and _handle_hslider_input(event, focused_control):
		return true

	if Utils.is_maybe_action_pressed(event, "ui_accept_%s" % _device):
		if not focused_control.is_visible_in_tree():
			return true
		if focused_control is BaseButton:
			if focused_control.disabled:
				return true
			if focused_control is OptionButton:
				_open_option_button(focused_control)
			elif focused_control.toggle_mode:
				var toggled = not focused_control.pressed
				focused_control.set_pressed_no_signal(toggled)
				
				
				
				FocusEmulatorSignal.emit(focused_control, "toggled", player_index, toggled)
			else:
				FocusEmulatorSignal.emit(focused_control, "pressed", player_index)
		return true

	var previous: = focused_control
	var result: = _get_focus_neighbour_for_event(event, previous)
	var new = result.control
	if new == null or new == previous:
		return result.input_matched_action
	assert (result.input_matched_action, "result.input_matched_action")
	_set_focused_control_with_style(new, false)
	FocusEmulatorSignal.emit(previous, "focus_exited", player_index)
	FocusEmulatorSignal.emit(new, "focus_entered", player_index)
	return true


func _open_option_button(button: OptionButton) -> void :
	
	var popup = button.get_popup()
	var size = button.rect_size
	popup.rect_global_position = button.rect_global_position + Vector2(0, size.y)
	popup.rect_size = Vector2(size.x, 0)
	if button.selected > - 1 and not popup.is_item_disabled(button.selected):
		popup.set_current_index(button.selected)
	else:
		for i in popup.get_item_count():
			if not popup.is_item_disabled(i):
				popup.set_current_index(i)
				break
	popup.popup()
	
	
	
	_set_focused_control_with_style(button, false)


func _handle_popup_menu_input(event: InputEvent, popup: PopupMenu) -> bool:
	var allow_echo: = true
	var item_count = popup.get_item_count()

	if event.is_action_pressed("ui_up_%s" % _device, allow_echo):
		popup.set_current_index((popup.get_current_index() - 1 + item_count) % item_count)
		return true
	elif event.is_action_pressed("ui_down_%s" % _device, allow_echo):
		popup.set_current_index((popup.get_current_index() + 1) % item_count)
		return true
	elif event.is_action_pressed("ui_accept_%s" % _device):
		var id = popup.get_item_id(popup.get_current_index())
		FocusEmulatorSignal.emit(popup, "id_pressed", player_index, id)
		FocusEmulatorSignal.emit(popup, "index_pressed", player_index, popup.get_current_index())
		popup.hide()
		return true

	return false


func _handle_hslider_input(event: InputEvent, slider: HSlider) -> bool:
	var allow_echo: = true
	if not event.is_action_pressed("ui_left_%s" % _device, allow_echo) and not event.is_action_pressed("ui_right_%s" % _device, allow_echo):
		return false
	var step: = slider.step
	if event.is_action_pressed("ui_left_%s" % _device, allow_echo):
		step = - step
	slider.value = clamp(slider.value + step, slider.min_value, slider.max_value)
	FocusEmulatorSignal.emit(slider, "value_changed", player_index, slider.value)
	return true


func _set_focused_control_with_style(control: Control, emit_signals: bool) -> void :
	if focused_control == control:
		return

	var previous: = focused_control
	_clear_focused_control()
	_connect_focused_control(control)
	focused_control = control

	_focused_control_index = control.get_index()
	_focused_parent = control.get_parent()
	_ensure_control_visible(control)
	
	_set_focus_style(control)
	
	var focus_owner = control.get_focus_owner()
	if focus_owner:
		FocusEmulatorSignal.set_expected_control(control, player_index)
		focus_owner.release_focus()

	if not emit_signals:
		return
	if previous and focus_owner != previous:
		
		FocusEmulatorSignal.emit(previous, "focus_exited", player_index)
	FocusEmulatorSignal.emit(focused_control, "focus_entered", player_index)


func _set_focus_style(control: Control) -> void :
	if not control.has_meta("original_stylebox_overrides"):
		var stylebox_overrides = {}
		for name in _stylebox_theme_names():
			if control.has_stylebox_override(name):
				stylebox_overrides[name] = control.get_stylebox(name)
		control.set_meta("original_stylebox_overrides", stylebox_overrides)

	if not control.has_meta("original_focus_stylebox"):
		if control.has_stylebox("focus"):
			control.set_meta("original_focus_stylebox", control.get_stylebox("focus"))
		elif control.has_stylebox("grabber_area_highlight"):
			control.set_meta("original_focus_stylebox", control.get_stylebox("grabber_area_highlight"))

	if not control.has_meta("original_color_overrides"):
		var color_overrides = {}
		for name in _color_theme_names():
			if control.has_color_override(name):
				color_overrides[name] = control.get_color(name)
		control.set_meta("original_color_overrides", color_overrides)

	if control is Button and not control.has_meta("original_flat"):
		control.set_meta("original_flat", control.flat)
		control.flat = false

	if control is TextureButton:
		control.set_meta("original_texture_normal", control.texture_normal)
		control.texture_normal = control.texture_focused

	control.set_meta("original_self_modulate", control.self_modulate)

	var player_indices = control.get_meta("focus_player_indices", [])
	if not player_indices.has(player_index):
		player_indices.push_back(player_index)
	control.set_meta("focus_player_indices", player_indices)
	var _updated = _update_focus_style_for_players(control)


func _clear_focus_style(control: Control) -> void :
	var player_indices = control.get_meta("focus_player_indices", [])
	player_indices.erase(player_index)
	control.set_meta("focus_player_indices", player_indices)

	if _update_focus_style_for_players(control):
		return

	
	var stylebox_overrides = control.get_meta("original_stylebox_overrides")
	control.remove_meta("original_stylebox_overrides")
	control.remove_meta("original_focus_stylebox")

	var color_overrides = control.get_meta("original_color_overrides")
	control.remove_meta("original_color_overrides")

	for name in _stylebox_theme_names():
		control.remove_stylebox_override(name)
		if stylebox_overrides.has(name):
			control.add_stylebox_override(name, stylebox_overrides[name])

	for name in _color_theme_names():
		control.remove_color_override(name)
		if color_overrides.has(name):
			control.add_color_override(name, color_overrides[name])

	if control.has_meta("original_flat"):
		control.flat = control.get_meta("original_flat")
		control.remove_meta("original_flat")

	if control.has_meta("original_texture_normal"):
		control.texture_normal = control.get_meta("original_texture_normal")
		control.remove_meta("original_texture_normal")

	control.self_modulate = control.get_meta("original_self_modulate")
	control.remove_meta("original_self_modulate")


func _update_focus_style_for_players(control: Control) -> bool:
	var base_data = _find_control_base_data(control)
	if base_data == null:
		printerr("Focus base not found for control: %s" % control)
		return false

	
	for child in get_parent().get_children():
		if child.get_class() == get_class():
			
			
			
			child.set_process(true)

	var player_indices = control.get_meta("focus_player_indices", [])
	if player_indices.empty():
		return false

	
	if control.focus_mode == Control.FOCUS_NONE:
		return true

	var focus_player_index = player_indices[0]

	if control.has_meta("original_focus_stylebox"):
		var focus_stylebox = control.get_meta("original_focus_stylebox")
		if focus_stylebox is StyleBoxFlat:
			focus_stylebox = focus_stylebox.duplicate()
			if base_data.apply_player_color:
				CoopService.change_stylebox_for_player(focus_stylebox, focus_player_index)
			for name in _stylebox_theme_names():
				control.add_stylebox_override(name, focus_stylebox)

	var focus_color = control.get_color("font_color_focus")
	for name in _color_theme_names():
		control.add_color_override(name, focus_color)

	if control is TextureButton and base_data.apply_player_color:
		var player_color = CoopService.get_player_color(focus_player_index)
		control.self_modulate = Color.white.linear_interpolate(player_color, 0.7)

	return true


func _stylebox_theme_names() -> Array:
	return ["normal", "focus", "pressed", "grabber_area", "grabber_area_highlight"]


func _color_theme_names() -> Array:
	return ["font_color", "font_color_focus", "font_color_pressed"]


func _on_connected_players_updated(connected_players: Array) -> void :
	var player_count = connected_players.size()
	if player_index < 0 or player_index >= player_count:
		_clear_focused_control()
		_device = - 1
		return
	var player_info = connected_players[player_index]
	_device = player_info[0]


func _on_focus_changed(control: Control) -> void :
	if _device < 0 or control == focused_control:
		return
	if _find_control_base_data(control) == null:
		return
	
	_set_focused_control_with_style(control, true)


func _ensure_control_visible(control: Control) -> void :
	var scroll_container = _find_parent_scroll_container(control)
	if scroll_container != null:
		scroll_container.ensure_control_visible(control)


func _find_parent_scroll_container(control: Control) -> ScrollContainer:
	var parent = control.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			return parent
		parent = parent.get_parent()
	return null


func _clear_focused_control() -> void :
	if focused_control == null:
		return

	_disconnect_focused_control(focused_control)

	_clear_focus_style(focused_control)
	focused_control = null
	_focused_control_index = - 1
	_focused_parent = null


func _find_control_base_data(control: Control) -> FocusEmulatorBaseData:
	for i in _focus_base_nodes.size():
		var base = _focus_base_nodes[i]
		if base == control or base.is_a_parent_of(control):
			return focus_base_data[i]
	return null



func _connect_focused_control(control: Control) -> void :
	var _error = control.connect("item_rect_changed", self, "update")


func _disconnect_focused_control(control: Control) -> void :
	if control.is_connected("item_rect_changed", self, "update"):
		control.disconnect("item_rect_changed", self, "update")


class GetFocusNeighbourForEventResult:
	var control: Control = null
	var input_matched_action: = false


func _get_focus_neighbour_for_event(event: InputEvent, target: Control) -> GetFocusNeighbourForEventResult:
	var result = GetFocusNeighbourForEventResult.new()
	for action_name in _ui_move_action_names():
		var device_action_name: = "%s_%s" % [action_name, _device]
		
		if not event.is_action(device_action_name) or not Input.is_action_pressed(device_action_name):
			continue
		result.input_matched_action = true
		if event is InputEventJoypadMotion and not Utils.is_valid_joypad_motion_event(event):
			break
		var margin
		match action_name:
			"ui_left":
				margin = MARGIN_LEFT
			"ui_right":
				margin = MARGIN_RIGHT
			"ui_up":
				margin = MARGIN_TOP
			"ui_down":
				margin = MARGIN_BOTTOM

		var base_nodes = _focus_base_nodes.duplicate()
		
		
		for i in _focus_base_nodes.size():
			var base = _focus_base_nodes[i]
			if not base.is_a_parent_of(target):
				continue
			if focus_base_data[i].contain_horizontal_focus and (margin == MARGIN_LEFT or margin == MARGIN_RIGHT):
				base_nodes = [base]
				
				for path in focus_base_data[i].contain_horizontal_focus_exception_paths:
					base_nodes.append(get_node(path))
				break
			elif focus_base_data[i].contain_vertical_focus and (margin == MARGIN_TOP or margin == MARGIN_BOTTOM):
				base_nodes = [base]
				break

		
		for i in _focus_base_nodes.size():
			var base = _focus_base_nodes[i]
			if base.is_a_parent_of(target):
				continue
			var require_entry_from_control_paths = focus_base_data[i].require_entry_from_control_paths
			if require_entry_from_control_paths.empty():
				continue
			var entering_from_required_control: = false
			for path in require_entry_from_control_paths:
				var required_control = get_node(path)
				if target == required_control or required_control.is_a_parent_of(target):
					entering_from_required_control = true
					break
			if not entering_from_required_control:
				base_nodes.erase(base)

		var new = _get_focus_neighbour_for_control(target, base_nodes, margin)
		result.control = new
		break
	return result



func _get_focus_neighbour_for_control(target: Control, bases: Array, margin: int, count: int = 0) -> Control:
	if count >= 512:
		return null

	var neighbours: = []

	
	var focus_neighbour_path: = target.get_focus_neighbour(margin)
	if focus_neighbour_path and not focus_neighbour_path.is_empty():
		var neighbour: = target.get_node_or_null(focus_neighbour_path)
		if neighbour != null and neighbour is Control:
			neighbours.push_back(neighbour)

	
	var target_base_data: = _find_control_base_data(target)
	if target_base_data != null:
		for base_data_neighbour_path in target_base_data.get_focus_neighbour_paths(margin):
			if not base_data_neighbour_path or base_data_neighbour_path.is_empty():
				continue
			var neighbour: = get_node_or_null(base_data_neighbour_path)
			if neighbour != null and neighbour is Control:
				neighbours.push_back(neighbour)

	for neighbour in neighbours:
		if _filter_control(neighbour, bases):
			return neighbour

	
	if neighbours.size() == 1:
		return _get_focus_neighbour_for_control(neighbours[0], bases, margin, count + 1)

	var points: PoolVector2Array = PoolVector2Array()
	points.resize(4)

	var xform = target.get_global_transform()
	points[0] = xform.xform(Vector2(0, 0))
	points[1] = xform.xform(Vector2(target.rect_size.x, 0))
	points[2] = xform.xform(target.rect_size)
	points[3] = xform.xform(Vector2(0, target.rect_size.y))

	var dir = [
		Vector2( - 1, 0), 
		Vector2(0, - 1), 
		Vector2(1, 0), 
		Vector2(0, 1)
	]

	var vdir = dir[margin]

	var max_d = - 10000000.0
	for point in points:
		var d = vdir.dot(point)
		if d > max_d:
			max_d = d

	if bases.empty():
		var base = target
		while true:
			var parent = base.get_parent()
			if parent == null or parent is Viewport:
				break
			base = parent
		bases = [base]

	var result_data = FindFocusNeighbourResult.new()
	for base in bases:
		_window_find_focus_neighbour(target, base, vdir, points, max_d, result_data)
	return result_data.closest


class FindFocusNeighbourResult:
	var closest_dist: float = 10000000.0
	var closest: Control = null


func _window_find_focus_neighbour(target: Control, base: Node, dir: Vector2, p_points: Array, p_min: float, result: FindFocusNeighbourResult):
	if base is Viewport:
		return

	var c: = base as Control
	if c != null and c != target and _filter_control(c, null):
		var points = PoolVector2Array()
		points.resize(4)

		var xform = c.get_global_transform()
		points[0] = xform.xform(Vector2(0, 0))
		points[1] = xform.xform(Vector2(c.rect_size.x, 0))
		points[2] = xform.xform(c.rect_size)
		points[3] = xform.xform(Vector2(0, c.rect_size.y))

		var min_d = 10000000.0

		for point in points:
			var d = dir.dot(point)
			if d < min_d:
				min_d = d

		if min_d > p_min - 1e-05:
			for i in range(4):
				var la = p_points[i]
				var lb = p_points[(i + 1) % 4]

				for j in range(4):
					var fa = points[j]
					var fb = points[(j + 1) % 4]

					var closest_points = Geometry.get_closest_points_between_segments_2d(la, lb, fa, fb)
					var pa = closest_points[0]
					var pb = closest_points[1]
					var d = pa.distance_to(pb)
					if d < result.closest_dist:
						result.closest_dist = d
						result.closest = c

	for child in base.get_children():
		_window_find_focus_neighbour(target, child, dir, p_points, p_min, result)


func _filter_control(control: Control, bases) -> bool:
	if bases:
		var has_parent = false
		for base in bases:
			if base == control or base.is_a_parent_of(control):
				has_parent = true
				break
		if not has_parent:
			return false
	if control is BaseButton and control.disabled:
		return false
	return control.is_visible_in_tree() and control.focus_mode == Control.FOCUS_ALL


func _is_coop_ui_action(event: InputEvent) -> bool:
	for child in get_parent().get_children():
		if child.get_class() == get_class():
			var other_player_index = child.player_index
			var other_device = CoopService.get_remapped_player_device(other_player_index)
			if other_device < 0:
				continue
			for action in _ui_action_names():
				if Utils.is_maybe_action(event, "%s_%s" % [action, other_device]):
					return true
	return false





func _is_coop_action(event: InputEvent, action: String) -> bool:
	for child in get_parent().get_children():
		if child.get_class() == get_class():
			var other_player_index = child.player_index
			var other_device = CoopService.get_remapped_player_device(other_player_index)
			if other_device < 0:
				continue
			if Utils.is_maybe_action(event, "%s_%s" % [action, other_device]):
				return true
	return false


func get_class() -> String:
	return "FocusEmulator"


func _ui_action_names() -> Array:
	return ["ui_accept", "ui_select", "ui_info"] + _ui_move_action_names()


func _ui_move_action_names() -> Array:
	return ["ui_left", "ui_right", "ui_up", "ui_down"]
