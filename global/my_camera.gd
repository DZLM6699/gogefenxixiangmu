class_name MyCamera
extends Camera2D


const MIN_ZOOM: = 1.0

export  var dynamic_camera_enabled: = true
export  var move_speed_factor: = 0.98
export  var zoomed_in_fraction: = 0.4
export  var zoom_in_speed_factor: = 0.6
export  var zoomed_out_margin: = 500.0
export  var zoom_out_speed_factor: = 0.99

export  var snap_duration_secs: = 3.0

var targets: = []
var _max_bounds: Rect2
var _edge_size: float
var _first_update: = true
var _is_snapped: = false


var _snap_progress: = 0.0
var _snap_start_position: = Vector2.ZERO
var _snap_start_zoom: = Vector2.ZERO


func init(max_bounds: Rect2, edge_size: float) -> void :
	_max_bounds = max_bounds
	_edge_size = edge_size
	_is_snapped = not RunData.is_coop_run


func _process(delta: float) -> void :
	if _is_snapped:
		_process_internal(delta)






func _physics_process(delta: float) -> void :
	if not _is_snapped:
		_process_internal(delta)


func _process_internal(delta: float):
	var alive_targets = _get_alive_targets()
	if alive_targets.empty():
		return
	_update_position(alive_targets, delta)
	_adjust_zoom(alive_targets, delta)
	_first_update = false


func _update_position(alive_targets: Array, delta: float) -> void :
	var avg_pos = _get_average_target_position(alive_targets)
	var offset_pos = avg_pos + _calculate_offset(avg_pos)
	var edge_visibility = _calculate_edge_visibility()
	var snap_to_target = alive_targets.size() == 1
	global_position = _calculate_final_position(offset_pos, edge_visibility, snap_to_target, delta)


func _get_average_target_position(alive_targets: Array) -> Vector2:
	var avg_pos: Vector2 = Vector2.ZERO
	for target in alive_targets:
		avg_pos += target.global_position
	return avg_pos / len(alive_targets)



func _calculate_offset(avg_pos: Vector2) -> Vector2:
	var avg_pos_camera_bounds = _get_camera_bounds(avg_pos)
	var offset = Vector2.ZERO
	if avg_pos_camera_bounds.position.x < _max_bounds.position.x:
		offset.x += _max_bounds.position.x - avg_pos_camera_bounds.position.x
	if avg_pos_camera_bounds.end.x > _max_bounds.end.x:
		offset.x += _max_bounds.end.x - avg_pos_camera_bounds.end.x
	if avg_pos_camera_bounds.position.y < _max_bounds.position.y:
		offset.y += _max_bounds.position.y - avg_pos_camera_bounds.position.y
	if avg_pos_camera_bounds.end.y > _max_bounds.end.y:
		offset.y += _max_bounds.end.y - avg_pos_camera_bounds.end.y
	return offset


func _calculate_edge_visibility() -> Array:
	var left_and_right_visible = _max_bounds.size.x <= zoom.x * Utils.project_width or _max_bounds.size.x <= Utils.project_width
	var top_and_bottom_visible = _max_bounds.size.y <= zoom.y * Utils.project_height or _max_bounds.size.y <= Utils.project_height
	return [left_and_right_visible, top_and_bottom_visible]


func _calculate_final_position(
	offset_pos: Vector2, edge_visibility: Array, snap_to_target: bool, delta: float
) -> Vector2:
	if not dynamic_camera_enabled and RunData.is_coop_run:
		return _max_bounds.get_center()

	var left_and_right_visible = edge_visibility[0]
	var top_and_bottom_visible = edge_visibility[1]

	var target_x
	if left_and_right_visible:
		
		
		target_x = _max_bounds.get_center().x
	else:
		
		target_x = offset_pos.x

	var target_y
	if top_and_bottom_visible:
		
		target_y = _max_bounds.get_center().y
	else:
		
		target_y = offset_pos.y

	if _first_update or _is_snapped:
		
		return Vector2(target_x, target_y)

	if snap_to_target:
		if _snap_progress == 0.0:
			_snap_start_position = global_position
			_snap_start_zoom = zoom
		_snap_progress = min(1.0, _snap_progress + delta / snap_duration_secs)
		if _snap_progress == 1.0:
			_is_snapped = true
		return _snap_start_position.linear_interpolate(Vector2(target_x, target_y), _get_eased_snap_progress(_snap_progress))

	return global_position.linear_interpolate(Vector2(target_x, target_y), _dt_lerp_factor(move_speed_factor, delta))


func _get_camera_bounds(position: Vector2 = global_position) -> Rect2:
	var size = Vector2(Utils.project_width, Utils.project_height) * zoom
	return Rect2(position - size / 2, size)


func _adjust_zoom(alive_targets: Array, delta: float) -> void :
	if not dynamic_camera_enabled and RunData.is_coop_run:
		var z: = _get_zoom_for_bounds(_max_bounds)
		zoom = Vector2(z, z)
		return

	if _snap_progress > 0.0:
		zoom = _snap_start_zoom.linear_interpolate(Vector2(MIN_ZOOM, MIN_ZOOM), _get_eased_snap_progress(_snap_progress))
		return

	if alive_targets.empty():
		return

	
	var target_bounds_zoomed_in: = _get_target_bounds(alive_targets, _edge_size / zoom.x)
	var zoom_in: = _get_zoom_for_bounds(target_bounds_zoomed_in)

	var camera_bounds = _get_camera_bounds()
	
	if not camera_bounds.grow(0.5).encloses(target_bounds_zoomed_in):
		
		var z: = max(MIN_ZOOM, zoom_in)
		zoom = Vector2(z, z)
		return

	var target_bounds_zoomed_out: = _get_target_bounds(alive_targets, zoomed_out_margin)
	var zoom_out: = _get_zoom_for_bounds(target_bounds_zoomed_out)

	var z: = MIN_ZOOM
	var zoom_speed_factor
	var should_zoom_in = target_bounds_zoomed_in.size.x < Utils.project_width * zoomed_in_fraction and target_bounds_zoomed_in.size.y < Utils.project_height * zoomed_in_fraction
	if should_zoom_in:
		z = max(z, zoom_in)
		zoom_speed_factor = zoom_in_speed_factor
	else:
		z = max(z, zoom_out)
		zoom_speed_factor = zoom_out_speed_factor
	zoom = zoom.linear_interpolate(Vector2(z, z), _dt_lerp_factor(zoom_speed_factor, delta))


func _get_target_bounds(alive_targets: Array, margin: float) -> Rect2:
	if alive_targets.empty():
		return Rect2(Vector2.ZERO, Vector2.ZERO)

	var rect: = Rect2(alive_targets[0].global_position, Vector2.ZERO)
	for i in range(1, alive_targets.size()):
		rect = rect.expand(alive_targets[i].global_position)
	return rect.grow(margin).clip(_max_bounds)



func _get_zoom_for_bounds(bounds: Rect2) -> float:
	var camera_bounds = _get_camera_bounds().clip(_max_bounds)
	var left_diff = camera_bounds.position.x - bounds.position.x
	var right_diff = bounds.end.x - camera_bounds.end.x
	var top_diff = camera_bounds.position.y - bounds.position.y
	var bottom_diff = bounds.end.y - camera_bounds.end.y

	var x_zoom_adjust = max(right_diff, left_diff) / Utils.project_width
	var y_zoom_adjust = max(bottom_diff, top_diff) / Utils.project_height
	return max(zoom.x + x_zoom_adjust, zoom.y + y_zoom_adjust)


func _get_alive_targets() -> Array:
	var alive_targets: = []
	for target in targets:
		if not target.dead:
			alive_targets.push_back(target)
	return alive_targets




func _dt_lerp_factor(speed_factor: float, dt: float) -> float:
	return 1.0 - pow(1.0 - speed_factor, dt)


func _get_eased_snap_progress(snap_progress: float) -> float:
	
	
	return ease(snap_progress, 0.2)
