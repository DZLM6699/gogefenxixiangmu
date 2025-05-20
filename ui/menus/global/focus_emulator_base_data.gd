class_name FocusEmulatorBaseData
extends Resource

export (NodePath) var path
export (bool) var apply_player_color: = false



export (bool) var contain_horizontal_focus: = false

export (Array, NodePath) var contain_horizontal_focus_exception_paths

export (bool) var contain_vertical_focus: = false


export (Array, NodePath) var require_entry_from_control_paths


export (Array, NodePath) var focus_neighbour_top_paths
export (Array, NodePath) var focus_neighbour_bottom_paths
export (Array, NodePath) var focus_neighbour_left_paths
export (Array, NodePath) var focus_neighbour_right_paths


func get_focus_neighbour_paths(margin: int) -> Array:
	match margin:
		MARGIN_LEFT:
			return focus_neighbour_left_paths
		MARGIN_TOP:
			return focus_neighbour_top_paths
		MARGIN_RIGHT:
			return focus_neighbour_right_paths
		MARGIN_BOTTOM:
			return focus_neighbour_bottom_paths
	return []
