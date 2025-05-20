class_name Effect
extends Resource

enum Sign { POSITIVE, NEGATIVE, NEUTRAL, FROM_VALUE, FROM_ARG, OVERRIDE }
enum StorageMethod { SUM, KEY_VALUE, REPLACE , APPEND_KEY, APPEND_KEY_VALUE }

export(String) var key := ""

export(String) var text_key := ""

export(int) var value := 0


export(String) var custom_key := ""


export(StorageMethod) var storage_method = StorageMethod.SUM

export(Sign) var effect_sign := Sign.FROM_VALUE

export(Array, Resource) var custom_args

var curse_factor: float = 0.0
var base_value = 0
var _custom_args_added := false

static func get_id() -> String:
	return "effect"


func apply(player_index: int) -> void:

	if key == "": return

	var effects = RunData.get_player_effects(player_index)
	if storage_method == StorageMethod.KEY_VALUE:
		var effect_items: Array = effects[custom_key]
		for existing_item in effect_items:
			if existing_item[0] == key:
				existing_item[1] += value
				return
		effect_items.push_back([key, value])
	elif storage_method == StorageMethod.APPEND_KEY:
		if not key in effects[custom_key]:
			effects[custom_key].append(key)
	elif storage_method == StorageMethod.APPEND_KEY_VALUE:
		effects[custom_key].append([key, value])
	elif storage_method == StorageMethod.REPLACE:
		base_value = effects[key]
		effects[key] = value
	else:
		effects[key] += value
	Utils.reset_stat_cache(player_index)


func unapply(player_index: int) -> void:

	if key == "": return

	var effects = RunData.get_player_effects(player_index)
	if storage_method == StorageMethod.KEY_VALUE:
		var effect_items: Array = effects[custom_key]
		for i in effect_items.size():
			var effect_item = effect_items[i]
			if effect_item[0] == key:
				effect_item[1] -= value
				if effect_item[1] == 0:
					effect_items.remove(i)
				return
	elif storage_method == StorageMethod.APPEND_KEY:
		effects[custom_key].erase(key)
	elif storage_method == StorageMethod.APPEND_KEY_VALUE:
		var effect_items: Array = effects[custom_key]
		for i in effect_items.size():
			var effect_item = effect_items[i]
			if effect_item[0] == key and int(effect_item[1]) == value:
				effect_items.remove(i)
				return
	elif storage_method == StorageMethod.REPLACE:
		effects[key] = base_value
	else:
		effects[key] -= value
	Utils.reset_stat_cache(player_index)


func get_text(player_index: int, colored: bool = true) -> String:
	var key_text = key.to_upper() if text_key.length() == 0 else text_key.to_upper()
	var args = get_args(player_index)
	var signs = []

	for i in args:
		signs.push_back(get_sign(effect_sign, value))

	if not _custom_args_added:
		_add_custom_args()
		_custom_args_added = true

	for custom_arg in custom_args:
		var i = custom_arg.arg_index
		if i >= args.size():
			for j in (i - args.size()) + 1:
				args.push_back("")
				signs.push_back(Sign.NEUTRAL)

		args[i] = get_arg_value(custom_arg, args[i], player_index)
		signs[i] = get_sign(custom_arg.arg_sign, int(args[i]))
		args[i] = get_formatted(custom_arg.arg_format, args[i], custom_arg.arg_value)

	return Text.text(key_text, args, [] if !colored else signs)


func get_arg_value(custom_arg: CustomArg, p_base_value: String, player_index: int) -> String:
	var from_arg_value = custom_arg.arg_value
	var from_arg_key = custom_arg.arg_key
	var final_value = p_base_value

	if from_arg_value != ArgValue.USUAL:
		match from_arg_value:
			ArgValue.VALUE: final_value = str(value)
			ArgValue.ABS_VALUE: final_value = str(abs(value))
			ArgValue.KEY:
				var arg_key = key if from_arg_key.empty() else from_arg_key
				final_value = str(tr(arg_key.to_upper()))
			ArgValue.UNIQUE_WEAPONS:
				var nb = RunData.get_unique_weapon_ids(player_index).size()
				final_value = str(value * nb)
			ArgValue.ADDITIONAL_WEAPONS:
				var weapons = RunData.get_player_weapons(player_index)
				var nb = weapons.size()
				final_value = str(value * nb)
			ArgValue.TIER:
				var val = "TIER_I"
				if value == 1: val = "TIER_II"
				elif value == 2: val = "TIER_III"
				elif value == 3: val = "TIER_IV"
				final_value = tr(val)
			ArgValue.SCALING_STAT:



				var show_plus_prefix := false
				final_value = Utils.get_scaling_stat_icon_text(key, value/100.0, show_plus_prefix)
			ArgValue.SCALING_STAT_VALUE:
				final_value = str(WeaponService.sum_scaling_stat_values([[key, value/100.0]], player_index))
			ArgValue.MAX_NB_OF_WAVES:
				final_value = str(RunData.nb_of_waves)
			ArgValue.TIER_IV_WEAPONS:
				var weapons = RunData.get_player_weapons(player_index)
				var nb_tier_iv_weapons = 0
				for weapon in weapons:
					if weapon.tier >= Tier.LEGENDARY:
						nb_tier_iv_weapons += 1
				final_value = str(value * nb_tier_iv_weapons)
			ArgValue.TIER_I_WEAPONS:
				var weapons = RunData.get_player_weapons(player_index)
				var nb_tier_i_weapons = 0
				for weapon in weapons:
					if weapon.tier <= Tier.COMMON:
						nb_tier_i_weapons += 1
				final_value = str(value * nb_tier_i_weapons)
			_: print("wrong value")
	return final_value


func get_sign(from_sign: int, from_value: int) -> int:

	var final_sign = from_sign

	if from_sign == Sign.FROM_VALUE:
		final_sign = Sign.POSITIVE if value > 0 else Sign.NEGATIVE if value < 0 else Sign.NEUTRAL
	elif from_sign == Sign.FROM_ARG:
		final_sign = Sign.POSITIVE if from_value > 0 else Sign.NEGATIVE if from_value < 0 else Sign.NEUTRAL
	else:
		final_sign = from_sign

	return final_sign


func get_formatted(from_format: int, from_value: String, base_arg_value: int) -> String:
	var formatted = from_value

	if from_format != Format.USUAL:
		match from_format:
			Format.PERCENT: formatted = str(float(from_value) / 100.0)
			Format.ARG_VALUE_AS_NUMBER: formatted = str(base_arg_value)
			Format.REMOVE_OPERATOR: formatted = from_value.replace("-", "")
			_: print("wrong format")

	return formatted


func get_args(_player_index: int) -> Array:
	var displayed_key = key

	if custom_key == "starting_weapon":
		displayed_key = key.substr(0, key.length() - 2)

	return [str(value), tr(displayed_key.to_upper())]


func serialize() -> Dictionary:

	var custom_args_serialized = []

	for custom_arg in custom_args:
		custom_args_serialized.push_back(custom_arg.serialize())

	return {
		"effect_id": get_id(),
		"key": key,
		"custom_key": custom_key,
		"text_key": text_key,
		"storage_method": storage_method,
		"value": str(value),
		"effect_sign": effect_sign,
		"base_value": base_value,
		"curse_factor": curse_factor,
		"custom_args": custom_args_serialized
	}


func deserialize_and_merge(effect: Dictionary) -> void:
	key = effect.key
	custom_key = effect.custom_key
	text_key = effect.text_key
	value = effect.value as int
	effect_sign = effect.effect_sign as int
	storage_method = effect.storage_method as int
	base_value = effect.base_value
	curse_factor = effect.curse_factor if "curse_factor" in effect else 0.0

	if "custom_args" in effect:
		var deserialized_custom_args = []
		for serialized_custom_arg in effect.custom_args:
			var deserialized_custom_arg = CustomArg.new()
			deserialized_custom_arg.deserialize_and_merge(serialized_custom_arg)
			deserialized_custom_args.push_back(deserialized_custom_arg)
		custom_args = deserialized_custom_args


func _add_custom_args() -> void:

	return
