class_name UpgradeData
extends ItemData

export (String) var upgrade_id = ""


func get_name_text() -> String:
	var tier_number = ItemService.get_tier_number(tier)
	return tr(name) + (" " + tier_number if tier_number != "" else "")
