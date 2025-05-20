class_name ZoneSelectionButton
extends OptionButton


func _ready() -> void :
	for zone_data in ZoneService.zones:
		add_item(zone_data.name, zone_data.my_id)
