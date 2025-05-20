class_name PlatformType

enum {STEAM, EPIC, LOCAL}
const type_names: = ["STEAM", "EPIC", "LOCAL"]


static func get_type_as_string(type: int) -> String:
	if 0 <= type and type < type_names.size():
			return type_names[type]
	printerr("Type with value: %s not found" % type)
	return ""
