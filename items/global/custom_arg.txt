class_name CustomArg
extends Resource


enum Sign{POSITIVE, NEGATIVE, NEUTRAL, FROM_VALUE, FROM_ARG, OVERRIDE}
enum ArgValue{
	USUAL = 0, 
	VALUE = 1, 
	KEY = 2, 
	UNIQUE_WEAPONS = 3, 
	ADDITIONAL_WEAPONS = 4, 
	TIER = 5, 
	SCALING_STAT = 6, 
	SCALING_STAT_VALUE = 7, 
	MAX_NB_OF_WAVES = 8, 
	TIER_IV_WEAPONS = 9, 
	TIER_I_WEAPONS = 10, 
	ABS_VALUE = 11, 
}
enum Format{USUAL, PERCENT, ARG_VALUE_AS_NUMBER, REMOVE_OPERATOR}


export (int) var arg_index = 0
export (Sign) var arg_sign = Sign.FROM_ARG
export (ArgValue) var arg_value = ArgValue.USUAL
export (Format) var arg_format = Format.USUAL
export (String) var arg_key: = ""


func deserialize_and_merge(serialized: Dictionary) -> void :
	arg_index = serialized.arg_index as int
	arg_sign = serialized.arg_sign as int
	arg_value = serialized.arg_value as int
	arg_format = serialized.arg_format as int
	arg_key = serialized.arg_key


func serialize() -> Dictionary:
	return {
		"arg_index": arg_index, 
		"arg_sign": arg_sign, 
		"arg_value": arg_value, 
		"arg_format": arg_format, 
		"arg_key": arg_key, 
	}
