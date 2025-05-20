class_name ItemData
extends ItemParentData

export(int) var max_nb = -1
export(Array, Resource) var item_appearances
export(Array, String) var tags
export(Resource) var replaced_by


func get_category() -> int:
	return Category.ITEM


func serialize() -> Dictionary:

	var serialized = .serialize()

	serialized.max_nb = str(max_nb)
	serialized.tags = tags

	var serialized_appearances = []

	for appearance in item_appearances:
		serialized_appearances.push_back(appearance.serialize())

	serialized.item_appearances = serialized_appearances

	if replaced_by:
		serialized.replaced_by = replaced_by.serialize()

	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)

	max_nb = serialized.max_nb as int
	tags = serialized.tags

	if serialized.has("replaced_by"):
		var item = ItemService.get_element(ItemService.items, serialized.replaced_by.my_id)
		item.deserialize_and_merge(serialized.replaced_by)
		replaced_by = item

	var deserialized_appearances = []

	for appearance in serialized.item_appearances:
		var deserialized = ItemAppearanceData.new()
		deserialized.deserialize_and_merge(appearance)
		deserialized_appearances.push_back(deserialized)

	item_appearances = deserialized_appearances
